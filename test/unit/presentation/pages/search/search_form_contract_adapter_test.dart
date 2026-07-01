import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_generic/kuron_generic.dart';
import 'package:nhasixapp/presentation/pages/search/search_form_contract_adapter.dart';

void main() {
  group('SearchFormContractAdapter', () {
    test('preserves canonical field order, options, labels, and hidden fields',
        () {
      final contract = DynamicSearchFormContract(
        urlPattern: 'search',
        dataSources: const <String, Object?>{
          'mangaTags': <String, Object?>{
            'endpoint': '/manga/tag',
          },
        },
        fields: const <SearchFormFieldContract>[
          SearchFormFieldContract(
            id: 'query',
            queryParam: 's',
            type: SearchFormFieldType.text,
            label: 'Search',
          ),
          SearchFormFieldContract(
            id: '_sort',
            queryParam: 'orderby',
            type: SearchFormFieldType.sort,
            label: 'Sort',
            options: <SearchFormFieldOption>[
              SearchFormFieldOption(value: 'date', label: 'Newest'),
              SearchFormFieldOption(value: 'popular', label: 'Popular'),
            ],
          ),
          SearchFormFieldContract(
            id: 'genre',
            queryParam: 'genre[]',
            type: SearchFormFieldType.checkbox,
            label: 'Genre',
            loadFromTags: true,
            tagType: 'genre',
            tagSourceUrl: 'https://example.com/tags.json',
            options: <SearchFormFieldOption>[
              SearchFormFieldOption(value: 'action', label: 'Action'),
            ],
          ),
          SearchFormFieldContract(
            id: 'includedTag',
            queryParam: 'includedTags[]',
            type: SearchFormFieldType.tag,
            label: 'Included Tags',
            multiInput: true,
            uiSelector: 'picker',
            uiDataSource: 'mangaTags',
          ),
          SearchFormFieldContract(
            id: '_page',
            queryParam: 'page',
            type: SearchFormFieldType.hidden,
            label: 'Page',
          ),
        ],
      );

      final form = SearchFormContractAdapter.toSearchFormConfig(contract);
      expect(form.params.keys,
          <String>['query', '_sort', 'genre', 'includedTag', '_page']);
      expect(form.params['query']?.type, 'text');
      expect(form.params['_sort']?.type, 'sort');
      final sortOptions = form.params['_sort']?.options;
      expect(sortOptions, isNotNull);
      expect(sortOptions!.length, 2);
      expect(sortOptions[0].value, 'date');
      expect(sortOptions[0].label, 'Newest');
      expect(sortOptions[1].value, 'popular');
      expect(sortOptions[1].label, 'Popular');
      expect(form.params['genre']?.type, 'checkbox');
      expect(form.params['_page']?.type, 'page');

      final raw = SearchFormContractAdapter.toRawSearchForm(contract);
      expect(raw['dataSources'], containsPair('mangaTags', isA<Map>()));
      final params = raw['params'] as Map<String, dynamic>;
      expect(params['_sort']['label'], 'Sort');
      expect(
        params['_sort']['options'],
        <Map<String, dynamic>>[
          <String, dynamic>{'value': 'date', 'label': 'Newest'},
          <String, dynamic>{'value': 'popular', 'label': 'Popular'},
        ],
      );
      expect(params['includedTag']['ui']['selector'], 'picker');
      expect(params['includedTag']['ui']['dataSource'], 'mangaTags');
      expect(params['genre']['loadFromTags'], true);
      expect(params['genre']['tagType'], 'genre');
      expect(params['genre']['tagSourceUrl'], 'https://example.com/tags.json');
      expect(params['_page']['type'], 'page');
    });
  });
}
