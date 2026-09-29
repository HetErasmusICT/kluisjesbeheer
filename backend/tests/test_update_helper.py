"""The update helper that install/enable-git-update.sh writes to the server.

The app user owns /opt/kluisjesbeheer and its .git. Whatever runs as root there (git, npm,
pip) would follow config or scripts the app user can change: git config (core.fsmonitor,
hooks) and package.json scripts. A compromised web app could then run commands as root via
'sudo kluisjes-update'. So the root helper only starts the work as the app user and does the
restart; the work itself lives in a root-owned script (found 29-09-2026).
"""
import os
import re

SCRIPT = os.path.join(os.path.dirname(__file__), '..', '..', 'install', 'enable-git-update.sh')


def _tekst():
    with open(SCRIPT, encoding='utf-8') as f:
        return f.read()


def _heredoc(tekst, doel, merk):
    m = re.search(r'cat > %s <<%s\n(.*?)\n%s\n' % (re.escape(doel), merk, merk), tekst, re.S)
    assert m, 'heredoc voor %s ontbreekt' % doel
    return m.group(1)


def test_root_helper_doet_zelf_niets_in_de_app_map():
    helper = _heredoc(_tekst(), '/usr/local/sbin/kluisjes-update', 'HELPER')
    code = '\n'.join(r for r in helper.splitlines() if not r.lstrip().startswith('#'))
    for verboden in (r'\bgit\s', r'\bnpm\s', r'\bpip\b', r'\bsqlite3\b', r'\bchown\b'):
        assert not re.search(verboden, code), '%r hoort niet als root te draaien' % verboden
    assert '$ALS_APP /usr/local/lib/kluisjes-update-werk' in code
    assert 'systemctl restart' in code
    assert re.search(r'^ALS_APP="runuser -u \$APP_USER -- ', _tekst(), re.M)


def test_het_werk_zit_in_een_script_van_root():
    tekst = _tekst()
    werk = _heredoc(tekst, '/usr/local/lib/kluisjes-update-werk', 'WERK')
    for nodig in ('pull --ff-only', 'npm ci', 'npm run build', 'install -q -r', 'sqlite3'):
        assert nodig in werk, '%r ontbreekt in het werkscript' % nodig
    assert 'chown root:root /usr/local/lib/kluisjes-update-werk' in tekst
    assert 'chmod 0755 /usr/local/lib/kluisjes-update-werk' in tekst


def test_nergens_safe_directory():
    assert 'safe.directory' not in _tekst()


INSTALL = os.path.join(os.path.dirname(__file__), '..', '..', 'install.sh')


def _install_heredoc(merk):
    with open(INSTALL, encoding='utf-8') as f:
        tekst = f.read()
    # Only inside install_update_helper(): the cert helper uses the same heredoc marker.
    deel = tekst[tekst.index('install_update_helper() {'):]
    deel = deel[:deel.index('\n}\n')]
    m = re.search(r"<<'%s'\n(.*?)\n%s\n" % (merk, merk), deel, re.S)
    assert m, 'heredoc %s ontbreekt in install.sh' % merk
    return tekst, m.group(1)


def test_install_sh_root_helper_doet_zelf_niets_in_de_app_map():
    tekst, helper = _install_heredoc('HELPER_EOF')
    code = '\n'.join(r for r in helper.splitlines() if not r.lstrip().startswith('#'))
    for verboden in (r'\bgit\s', r'\bnpm\s', r'\bpip\b', r'\bsqlite3\b', r'\bchown\b'):
        assert not re.search(verboden, code), '%r hoort niet als root te draaien' % verboden
    assert 'runuser -u kluisjes -- ' in code and '/usr/local/lib/kluisjes-update-werk' in code
    assert 'systemctl restart kluisjesbeheer' in code
    assert 'safe.directory' not in tekst


def test_install_sh_werk_zit_in_een_script_van_root():
    tekst, werk = _install_heredoc('WERK_EOF')
    for nodig in ('pull --ff-only', 'npm ci', 'npm run build', 'install -q -r', 'sqlite3'):
        assert nodig in werk, '%r ontbreekt in het werkscript' % nodig
    assert 'chown root:root "$werk"' in tekst and 'chmod 755 "$werk"' in tekst


def test_eerste_build_draait_ook_als_de_app_user():
    tekst = _tekst()
    buiten = re.sub(r'cat > \S+ <<(\w+)\n.*?\n\1\n', '', tekst, flags=re.S)
    for regel in buiten.splitlines():
        if 'npm ci' in regel or 'npm run build' in regel:
            assert regel.lstrip().startswith('$ALS_APP '), 'npm als root: %s' % regel.strip()
