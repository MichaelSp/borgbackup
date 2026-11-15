"""Run the real init script with a fake Kubernetes API. Requires yq on PATH."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class RunsOnTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.output = self.root / 'output'
        self.output.mkdir()
        shutil.copy(Path(__file__).parents[1] / 'app/borgmatic-init', self.root / 'borgmatic-init')
        self.kubectl = self.root / 'kubectl'
        self.kubectl.write_text('''#!/bin/sh
set -eu
if [ "$2" = pvc ]; then
  [ "${MISSING_PVC:-false}" != true ] || exit 1
  printf pv
else
  printf '%s' "$PV_JSON"
fi
''')
        self.kubectl.chmod(0o755)
        self.pv = {'spec': {'local': {'path': '/node/data'}, 'nodeAffinity': {'required': {
            'nodeSelectorTerms': [{'matchExpressions': [{
                'key': 'kubernetes.io/hostname', 'operator': 'In', 'values': ['home']
            }]}]}}}}
        self.env = dict(os.environ, PATH=str(self.root) + ':' + os.environ['PATH'],
                        K8S_NODE_NAME='server', SOURCES_YAML=str(self.root / 'sources.json'),
                        DESTINATION=str(self.output), BORGMATIC_INIT_ALL_NODES='false',
                        RUNS_ON_ANY_NODE='server')

    def run_init(self, sources, success=True):
        (self.root / 'sources.json').write_text(json.dumps(sources))
        self.env['PV_JSON'] = json.dumps(self.pv)
        result = subprocess.run(['sh', str(self.root / 'borgmatic-init')], env=self.env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return {p.stem: p.read_text() for p in self.output.glob('*.yaml')}

    def test_any_pvc_follows_owner_and_pin_selects_one_node(self):
        sources = {'app': {'namespace': 'apps', 'pvc': 'data'},
                   'shared': {'type': 'fs', 'runs-on': 'server', 'source_directories': ['/shared']}}
        self.assertEqual(set(self.run_init(sources)), {'shared'})
        self.env['K8S_NODE_NAME'] = 'home'
        configs = self.run_init(sources)
        self.assertEqual(set(configs), {'app'})
        self.assertIn('hostname: "home"', configs['app'])

    def test_all_runs_everywhere_and_prunes_per_node(self):
        source = {'files': {'type': 'fs', 'runs-on': 'all', 'source_directories': ['/node']}}
        for node in ['server', 'home']:
            self.env['K8S_NODE_NAME'] = node
            config = self.run_init(source)['files']
            self.assertIn(f'hostname: "{node}"', config)
            self.assertNotIn('match_archives:', config)

    def test_catalog_retains_other_node_and_all_archive_hosts(self):
        self.env['BORGMATIC_INIT_ALL_NODES'] = 'true'
        configs = self.run_init({'app': {'namespace': 'apps', 'pvc': 'data'},
                                 'files': {'type': 'fs', 'runs-on': 'all', 'source_directories': ['/node']}})
        self.assertIn('hostname: "home"', configs['app'])
        self.assertIn('match_archives: "sh:*-files-[0-9]*"', configs['files'])

    def test_conflicting_pin_and_ambiguous_pv_fail(self):
        self.run_init({'app': {'namespace': 'apps', 'pvc': 'data', 'runs-on': 'server'}}, success=False)
        self.pv['spec']['nodeAffinity']['required']['nodeSelectorTerms'][0][
            'matchExpressions'][0]['values'] = ['server', 'home']
        self.run_init({'app': {'namespace': 'apps', 'pvc': 'data'}}, success=False)

    def test_missing_pvc_fails(self):
        self.env['MISSING_PVC'] = 'true'
        self.run_init({'app': {'namespace': 'apps', 'pvc': 'missing'}}, success=False)

    def test_any_non_pvc_uses_designated_node(self):
        source = {'files': {'type': 'fs', 'source_directories': ['/shared']}}
        self.assertEqual(set(self.run_init(source)), {'files'})
        self.env['K8S_NODE_NAME'] = 'home'
        self.assertEqual(self.run_init(source), {})

    def test_legacy_any_without_node_environment(self):
        self.env.pop('K8S_NODE_NAME')
        self.env.pop('RUNS_ON_ANY_NODE')
        self.assertEqual(set(self.run_init({'app': {'namespace': 'apps', 'pvc': 'data'}})), {'app'})


if __name__ == '__main__':
    unittest.main()
