#!/usr/bin/python3

# With this script you can
#
# - format a YAML file containing translations uniformly and detect
#   missing translations
#
# - extract a simplified non-structured linefeed-separated version for
#   human translators, and
#
# - re-import translations from such a non-structured file into an
#   existing YAML file.
#
# The re-importing works by using existing translation string values
# as keys. (False) assumption: identical strings in different context
# translate identically.

import yaml
from collections import OrderedDict

from yaml.emitter import Emitter, ScalarAnalysis

class MyEmitter(Emitter):
    def analyze_scalar(self, scalar):
        analysis = super(MyEmitter, self).analyze_scalar(scalar)
        analysis.allow_single_quoted = False
        return analysis
class OrderedDumper(yaml.Dumper, MyEmitter):
    pass

# from [1]
def ordered_load(stream, Loader=yaml.Loader, object_pairs_hook=OrderedDict):
    class OrderedLoader(Loader):
        pass
    def construct_mapping(loader, node):
        loader.flatten_mapping(node)
        return object_pairs_hook(loader.construct_pairs(node))
    OrderedLoader.add_constructor(
        yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG,
        construct_mapping
    )
    return yaml.load(stream, OrderedLoader)

# from [1]
def ordered_dump(data,
                stream=None,
                Dumper=yaml.Dumper,
                explicit_start=False,
                explicit_end=False,
                default_flow_style=False,
                indent=4,
                width=160,
                allow_unicode=True,
                **kwds):
    def _dict_representer(dumper, data):
        return dumper.represent_mapping(
            yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG,
            data.items()
        )
    OrderedDumper.add_representer(OrderedDict, _dict_representer)
    return yaml.dump(data, stream, OrderedDumper,
                explicit_start=explicit_start,
                explicit_end=explicit_end,
                default_flow_style=default_flow_style,
                indent=indent,
                width=width,
                allow_unicode=allow_unicode,
                **kwds
    )

def format(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        data = ordered_load(f)
        print(ordered_dump(data))

def _extract_all_keys(group, base_path=tuple()):
    keys = []
    if type(group) == list:
        for key, value in enumerate(group):
            new_key = base_path + (str(key),)
            if type(value) == str:
                keys.append(new_key)
            else:
                keys.extend(_extract_all_keys(value, base_path=new_key))
    else:
        for key, value in group.items():
            new_key = base_path + (key,)
            if type(value) == str:
                keys.append(new_key)
            else:
                keys.extend(_extract_all_keys(value, base_path=new_key))
    return keys

def extract(filename, languages=None, verify=True):
    with open(filename, 'r', encoding='utf-8') as f:
        data = ordered_load(f)
        if languages is None or len(languages) == 0:
            languages = set()
            for main_group in data.values():
                languages.update(main_group.keys())

        for main_group in data.values():
            keys = []
            for language in languages:
                try:
                    new_keys = _extract_all_keys(main_group[language])
                except KeyError:
                    pass
                for key in new_keys:
                    if key not in keys:
                        keys.append(key)
            for key in keys:
                for language in languages:
                    try:
                        group = main_group[language]
                        value = group
                        for part in key:
                            if type(value) == list:
                                part = int(part)
                            value = value[part]
                        val = value.strip()
                        if verify == False: print(val)
                    except KeyError:
                        print('Missing translation:', language, '.'.join(key))
                        continue
                if verify == False:
                    print("\n")

def _read_record(stream, languages):
    def eof(line): return line == ''
    record = dict()
    while True:
        line = stream.readline()
        if eof(line): return None
        if line.strip() == '':
            continue
        record[languages[0]] = line.strip().strip('"')
        line = stream.readline()
        if eof(line): return None
        record[languages[1]] = line.strip().strip('"')
        line = stream.readline()
        if eof(line): return None
        if not line.strip() == '':
            print("Error: expecting empty line between records at", line)
            exit(1)
        return record

def _find_keys(data, reference_lang, target_lang, reference_value, base_path=tuple()):
    keys = set()
    for key, val in data.items():
        new_key = base_path + (key,)
        if type(val) == str:
            if val == reference_value.strip('\'"'):
                keys.add(new_key)
        else:
            keys.update(
                _find_keys(
                    data[key],
                    reference_lang,
                    target_lang,
                    reference_value,
                    base_path=new_key
            ))
    return keys

def _inject_translation(data, key, value):
    target = data
    for part in key[:-1]:
        target = target.setdefault(part, OrderedDict())
    target[key[-1]] = value

def import_translations(
        input_filename=None, output_filename=None,
        reference_language=None, target_language=None):

    data = None
    with open(output_filename, 'r', encoding='utf-8') as f:
        data = ordered_load(f)
    with open(input_filename, 'r', encoding='utf-8') as f:
        # Input file format:
        # - records are separated by more than one newline
        # - there are two fields, separated by one newline
        #   - first field is reference language string
        #   - second field is new translation in target language
        records = []
        record = True
        while record != None:
            record = _read_record(f, [reference_language, target_language])
            if record: records.append(record)
    for record in records:
        keys = _find_keys(
            data,
            reference_language,
            target_language,
            record[reference_language])
        if len(keys) == 0:
            print("Error: no key found for", record[reference_language])
            exit(1)
        for key in keys:
            key = list(key)
            key[1] = target_language
            key = tuple(key)
            if not key:
                print("Key not found for", record[reference_language])
            else:
                _inject_translation(data, key, record[target_language])
    print(ordered_dump(data))

import sys
if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: (format | extract | import | verify) filenames [languages]\n")
        sys.exit(1)

    command = sys.argv[1]
    if command == 'format':
        format(sys.argv[2])
    elif command in ['extract', 'verify']:
        if command == 'verify':
            verify = True
            languages = None
        else:
            verify = False
            languages = sys.argv[3:]
        extract(sys.argv[2], languages=languages, verify=verify)
    elif command == 'import':
        import_translations(
            input_filename=sys.argv[2],
            output_filename=sys.argv[3],
            reference_language=sys.argv[4],
            target_language=sys.argv[5]
        )

# [1] http://stackoverflow.com/questions/5121931/in-python-how-can-you-load-yaml-mappings-as-ordereddicts
