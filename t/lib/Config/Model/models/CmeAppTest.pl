use strict;
use warnings;

return [
  {
    'element' => [
      'a_string',
      {
        'default' => 'test failed',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'CmeAppTest',
    'rw_config' => {
      'auto_create' => '1',
      'backend' => 'Yaml',
      'file' => 'cme-test.yml'
    }
  }
]
;

