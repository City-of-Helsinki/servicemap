#!/usr/bin/env python

import yaml
import yaml.constructor

try:
    # included in standard lib from Python 2.7
    from collections import OrderedDict
except ImportError:
    # try importing the backported drop-in replacement
    # it's available on PyPI
    from ordereddict import OrderedDict

class OrderedDictYAMLLoader(yaml.Loader):
    """
    A YAML loader that loads mappings into ordered dictionaries.
    """

    def __init__(self, *args, **kwargs):
        yaml.Loader.__init__(self, *args, **kwargs)

        self.add_constructor(u'tag:yaml.org,2002:map', type(self).construct_yaml_map)
        self.add_constructor(u'tag:yaml.org,2002:omap', type(self).construct_yaml_map)

    def construct_yaml_map(self, node):
        data = OrderedDict()
        yield data
        value = self.construct_mapping(node)
        data.update(value)

    def construct_mapping(self, node, deep=False):
        if isinstance(node, yaml.MappingNode):
            self.flatten_mapping(node)
        else:
            raise yaml.constructor.ConstructorError(None, None,
                'expected a mapping node, but found %s' % node.id, node.start_mark)

        mapping = OrderedDict()
        for key_node, value_node in node.value:
            key = self.construct_object(key_node, deep=deep)
            try:
                hash(key)
            except TypeError as exc:
                raise yaml.constructor.ConstructorError('while constructing a mapping',
                    node.start_mark, 'found unacceptable key (%s)' % exc, key_node.start_mark)
            value = self.construct_object(value_node, deep=deep)
            mapping[key] = value
        return mapping

f = open('locales/app.yaml')
d = yaml.load(f.read(), OrderedDictYAMLLoader)

def print_keys(path, out, lang, data):
    for k, val in data.items():
        k = str(k)
        k_path = path + [k]
        if isinstance(val, dict):
            print_keys(k_path, out, lang, val)
        else:
            out_key = '.'.join(k_path)
            if not out_key in out:
                out[out_key] = {}
            out[out_key][lang] = val


out = OrderedDict()
for section in d.keys():
    for lang in d[section].keys():
        print_keys([section], out, lang, d[section][lang])

LANG_CODES = ['fi', 'en', 'sv']

import csv

f = open('translations.csv', 'w')
writer = csv.writer(f)

for key, langs in out.items():
    row = []
    row.append(key)
    for l_code in LANG_CODES:
        row.append(langs.get(l_code, ''))
    print(row)
    writer.writerow(row)

f.close()
