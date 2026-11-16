___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "TAG",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "BerryCookie - Consent Banner and Consent Mode",
  "categories": [
    "UTILITY",
    "ANALYTICS",
    "ADVERTISING"
  ],
  "brand": {
    "id": "brand_berrycookie",
    "displayName": "BerryCookie"
  },
  "description": "Shows the BerryCookie cookie banner and runs Google Consent Mode v2: denied defaults per region until the visitor decides, then updates from the visitor's choice. Fire it on the Consent Initialization - All Pages trigger.",
  "containerContexts": [
    "WEB"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "publicKey",
    "displayName": "Website key",
    "simpleValueType": true,
    "help": "The public key of the website, shown in the BerryCookie dashboard under Websites > Install.",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      },
      {
        "type": "REGEX",
        "args": [
          "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
        ],
        "errorMessage": "The key looks like 3f2a9c1e-5b7d-4e8a-9c21-7d4e5f6a8b90."
      }
    ]
  },
  {
    "type": "SELECT",
    "name": "blockingMode",
    "displayName": "Script blocking",
    "macrosInSelect": false,
    "selectItems": [
      {
        "value": "manual",
        "displayValue": "Manual - Tag Manager decides with consent settings (recommended)"
      },
      {
        "value": "auto",
        "displayValue": "Automatic - BerryCookie also blocks known trackers added outside Tag Manager"
      }
    ],
    "simpleValueType": true,
    "defaultValue": "manual"
  },
  {
    "type": "PARAM_TABLE",
    "name": "defaultSettings",
    "displayName": "Consent Mode defaults",
    "help": "Applied before the visitor decides. With no rows, everything except security_storage is denied everywhere. Leave the region empty for every other region. Regions are ISO 3166-2 codes separated by commas, e.g. RO, DE, US-CA; the most specific region wins.",
    "paramTableColumns": [
      {
        "param": {
          "type": "TEXT",
          "name": "region",
          "displayName": "Region (empty = everywhere else)",
          "simpleValueType": true
        },
        "isUnique": true
      },
      {
        "param": {
          "type": "SELECT",
          "name": "analytics",
          "displayName": "Statistics (analytics_storage)",
          "macrosInSelect": false,
          "selectItems": [
            { "value": "denied", "displayValue": "Denied" },
            { "value": "granted", "displayValue": "Granted" }
          ],
          "simpleValueType": true,
          "defaultValue": "denied"
        },
        "isUnique": false
      },
      {
        "param": {
          "type": "SELECT",
          "name": "ads",
          "displayName": "Marketing (ad_storage, ad_user_data, ad_personalization)",
          "macrosInSelect": false,
          "selectItems": [
            { "value": "denied", "displayValue": "Denied" },
            { "value": "granted", "displayValue": "Granted" }
          ],
          "simpleValueType": true,
          "defaultValue": "denied"
        },
        "isUnique": false
      },
      {
        "param": {
          "type": "SELECT",
          "name": "preferences",
          "displayName": "Preferences (functionality_storage, personalization_storage)",
          "macrosInSelect": false,
          "selectItems": [
            { "value": "denied", "displayValue": "Denied" },
            { "value": "granted", "displayValue": "Granted" }
          ],
          "simpleValueType": true,
          "defaultValue": "denied"
        },
        "isUnique": false
      }
    ],
    "newRowButtonText": "Add region"
  },
  {
    "type": "GROUP",
    "name": "advanced",
    "displayName": "Advanced",
    "groupStyle": "ZIPPY_CLOSED",
    "subParams": [
      {
        "type": "TEXT",
        "name": "waitForUpdate",
        "displayName": "Wait for update (milliseconds)",
        "simpleValueType": true,
        "defaultValue": "500",
        "help": "How long Google tags wait for the visitor's stored or new choice before they use the defaults.",
        "valueValidators": [
          {
            "type": "NON_NEGATIVE_NUMBER"
          }
        ]
      },
      {
        "type": "CHECKBOX",
        "name": "adsDataRedaction",
        "checkboxText": "Redact ad click identifiers while marketing is denied (ads_data_redaction)",
        "simpleValueType": true,
        "defaultValue": true
      },
      {
        "type": "CHECKBOX",
        "name": "urlPassthrough",
        "checkboxText": "Pass ad click information through URLs (url_passthrough)",
        "simpleValueType": true,
        "defaultValue": false
      },
      {
        "type": "TEXT",
        "name": "scriptUrl",
        "displayName": "Script URL",
        "simpleValueType": true,
        "defaultValue": "https://cdn.berrycookie.com/bc.js",
        "help": "Change only when BerryCookie support asks you to."
      }
    ]
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

// BerryCookie for Google Tag Manager. Fire on "Consent Initialization - All Pages".
//
// 1. Consent Mode defaults per region (setDefaultConsentState), before any other tag runs.
// 2. A returning visitor's stored decision is applied at once (updateConsentState), read from the
//    first-party BerryCookieConsent cookie, as Google recommends for consent templates.
// 3. bc.js is loaded with consentmode=update: it shows the banner and, from then on, is the only
//    source of Consent Mode updates (it pushes the gtag "consent update" command to the dataLayer
//    after each decision, and in regions where the banner rules are opt-out). It never sends
//    defaults in this mode, and it does not repeat the stored decision on page load, so the
//    template and bc.js never send conflicting states.

const setDefaultConsentState = require('setDefaultConsentState');
const updateConsentState = require('updateConsentState');
const getCookieValues = require('getCookieValues');
const injectScript = require('injectScript');
const encodeUriComponent = require('encodeUriComponent');
const gtagSet = require('gtagSet');
const getType = require('getType');
const JSON = require('JSON');
const makeNumber = require('makeNumber');
const log = require('logToConsole');

const CONSENT_COOKIE = 'BerryCookieConsent';
const DEFAULT_SCRIPT_URL = 'https://cdn.berrycookie.com/bc.js';

const splitRegions = (value) => {
  if (!value) return [];
  return value.split(',').map((part) => part.trim().toUpperCase()).filter((part) => part.length > 0);
};

const grantedOrDenied = (value) => value === 'granted' ? 'granted' : 'denied';

// The same mapping as the SDK (src/consent-mode.ts).
const stateFromCategories = (categories) => {
  const has = (category) => categories.indexOf(category) >= 0;
  const marketing = has('marketing') ? 'granted' : 'denied';
  const statistics = has('statistics') ? 'granted' : 'denied';
  const preferences = has('preferences') ? 'granted' : 'denied';
  return {
    ad_storage: marketing,
    ad_user_data: marketing,
    ad_personalization: marketing,
    analytics_storage: statistics,
    functionality_storage: preferences,
    personalization_storage: preferences,
    security_storage: 'granted'
  };
};

// 1. Defaults. Consent Mode applies the most specific region, so the row order does not matter.
const waitForUpdate = makeNumber(data.waitForUpdate);
const rows = getType(data.defaultSettings) === 'array' && data.defaultSettings.length > 0 ?
  data.defaultSettings :
  [{ region: '', analytics: 'denied', ads: 'denied', preferences: 'denied' }];

rows.forEach((row) => {
  const ads = grantedOrDenied(row.ads);
  const analytics = grantedOrDenied(row.analytics);
  const preferences = grantedOrDenied(row.preferences);
  const defaults = {
    ad_storage: ads,
    ad_user_data: ads,
    ad_personalization: ads,
    analytics_storage: analytics,
    functionality_storage: preferences,
    personalization_storage: preferences,
    security_storage: 'granted',
    wait_for_update: waitForUpdate >= 0 ? waitForUpdate : 500
  };
  const regions = splitRegions(row.region);
  if (regions.length > 0) {
    defaults.region = regions;
  }
  setDefaultConsentState(defaults);
});

gtagSet({
  ads_data_redaction: data.adsDataRedaction === true,
  url_passthrough: data.urlPassthrough === true
});

// 2. A decision made on an earlier visit (the cookie holds URI-encoded JSON; getCookieValues decodes it).
const stored = getCookieValues(CONSENT_COOKIE);
if (stored && stored.length > 0) {
  const decision = JSON.parse(stored[0]);
  if (decision && getType(decision.cats) === 'array') {
    updateConsentState(stateFromCategories(decision.cats));
  }
}

// 3. The banner. A template cannot set attributes on the script tag, so bc.js reads its settings
// from the query string.
const url = (data.scriptUrl || DEFAULT_SCRIPT_URL) +
  '?key=' + encodeUriComponent(data.publicKey) +
  '&consentmode=update' +
  '&blockingmode=' + encodeUriComponent(data.blockingMode === 'auto' ? 'auto' : 'manual');

injectScript(url, data.gtmOnSuccess, () => {
  log('BerryCookie: bc.js could not be loaded from ' + url);
  data.gtmOnFailure();
}, 'berrycookie');


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_consent",
        "versionId": "1"
      },
      "param": [
        {
          "key": "consentTypes",
          "value": {
            "type": 2,
            "listItem": [
              { "type": 3, "mapKey": [ { "type": 1, "string": "consentType" }, { "type": 1, "string": "read" }, { "type": 1, "string": "write" } ], "mapValue": [ { "type": 1, "string": "ad_storage" }, { "type": 8, "boolean": true }, { "type": 8, "boolean": true } ] },
              { "type": 3, "mapKey": [ { "type": 1, "string": "consentType" }, { "type": 1, "string": "read" }, { "type": 1, "string": "write" } ], "mapValue": [ { "type": 1, "string": "ad_user_data" }, { "type": 8, "boolean": true }, { "type": 8, "boolean": true } ] },
              { "type": 3, "mapKey": [ { "type": 1, "string": "consentType" }, { "type": 1, "string": "read" }, { "type": 1, "string": "write" } ], "mapValue": [ { "type": 1, "string": "ad_personalization" }, { "type": 8, "boolean": true }, { "type": 8, "boolean": true } ] },
              { "type": 3, "mapKey": [ { "type": 1, "string": "consentType" }, { "type": 1, "string": "read" }, { "type": 1, "string": "write" } ], "mapValue": [ { "type": 1, "string": "analytics_storage" }, { "type": 8, "boolean": true }, { "type": 8, "boolean": true } ] },
              { "type": 3, "mapKey": [ { "type": 1, "string": "consentType" }, { "type": 1, "string": "read" }, { "type": 1, "string": "write" } ], "mapValue": [ { "type": 1, "string": "functionality_storage" }, { "type": 8, "boolean": true }, { "type": 8, "boolean": true } ] },
              { "type": 3, "mapKey": [ { "type": 1, "string": "consentType" }, { "type": 1, "string": "read" }, { "type": 1, "string": "write" } ], "mapValue": [ { "type": 1, "string": "personalization_storage" }, { "type": 8, "boolean": true }, { "type": 8, "boolean": true } ] },
              { "type": 3, "mapKey": [ { "type": 1, "string": "consentType" }, { "type": 1, "string": "read" }, { "type": 1, "string": "write" } ], "mapValue": [ { "type": 1, "string": "security_storage" }, { "type": 8, "boolean": true }, { "type": 8, "boolean": true } ] }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "get_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "cookieAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "cookieNames",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "BerryCookieConsent"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "inject_script",
        "versionId": "1"
      },
      "param": [
        {
          "key": "urls",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "https://cdn.berrycookie.com/*"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "write_data_layer",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keyPatterns",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "ads_data_redaction"
              },
              {
                "type": 1,
                "string": "url_passthrough"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: New visitor gets denied defaults and the banner script
  code: |-
    let injectedUrl;
    mock('injectScript', (url, onSuccess) => {
      injectedUrl = url;
      onSuccess();
    });
    mock('getCookieValues', () => []);

    runCode(mockData);

    assertApi('setDefaultConsentState').wasCalledWith({
      ad_storage: 'denied',
      ad_user_data: 'denied',
      ad_personalization: 'denied',
      analytics_storage: 'denied',
      functionality_storage: 'denied',
      personalization_storage: 'denied',
      security_storage: 'granted',
      wait_for_update: 500
    });
    assertApi('updateConsentState').wasNotCalled();
    assertApi('gtagSet').wasCalledWith({
      ads_data_redaction: true,
      url_passthrough: false
    });
    assertThat(injectedUrl).isEqualTo('https://cdn.berrycookie.com/bc.js?key=3f2a9c1e-5b7d-4e8a-9c21-7d4e5f6a8b90&consentmode=update&blockingmode=manual');
    assertApi('gtmOnSuccess').wasCalled();
    assertApi('gtmOnFailure').wasNotCalled();
- name: Regional rows set one default each, with the region list
  code: |-
    mock('injectScript', (url, onSuccess) => onSuccess());
    mock('getCookieValues', () => []);

    runCode({
      publicKey: mockData.publicKey,
      blockingMode: 'auto',
      waitForUpdate: '800',
      adsDataRedaction: false,
      urlPassthrough: true,
      defaultSettings: [
        { region: '', analytics: 'granted', ads: 'granted', preferences: 'granted' },
        { region: 'ro, de ,us-ca', analytics: 'denied', ads: 'denied', preferences: 'granted' }
      ]
    });

    assertApi('setDefaultConsentState').wasCalledWith({
      ad_storage: 'granted',
      ad_user_data: 'granted',
      ad_personalization: 'granted',
      analytics_storage: 'granted',
      functionality_storage: 'granted',
      personalization_storage: 'granted',
      security_storage: 'granted',
      wait_for_update: 800
    });
    assertApi('setDefaultConsentState').wasCalledWith({
      ad_storage: 'denied',
      ad_user_data: 'denied',
      ad_personalization: 'denied',
      analytics_storage: 'denied',
      functionality_storage: 'granted',
      personalization_storage: 'granted',
      security_storage: 'granted',
      wait_for_update: 800,
      region: ['RO', 'DE', 'US-CA']
    });
    assertApi('gtagSet').wasCalledWith({
      ads_data_redaction: false,
      url_passthrough: true
    });
- name: Automatic blocking is passed to bc.js
  code: |-
    let injectedUrl;
    mock('injectScript', (url, onSuccess) => {
      injectedUrl = url;
      onSuccess();
    });
    mock('getCookieValues', () => []);

    runCode({
      publicKey: mockData.publicKey,
      blockingMode: 'auto',
      defaultSettings: [],
      waitForUpdate: '500',
      scriptUrl: 'https://cdn.berrycookie.com/bc.js'
    });

    assertThat(injectedUrl).isEqualTo('https://cdn.berrycookie.com/bc.js?key=3f2a9c1e-5b7d-4e8a-9c21-7d4e5f6a8b90&consentmode=update&blockingmode=auto');
- name: Returning visitor's decision is applied before bc.js loads
  code: |-
    mock('injectScript', (url, onSuccess) => onSuccess());
    mock('getCookieValues', () => ['{"id":"a","v":1,"cats":["necessary","statistics"],"all":[],"act":"Custom","ts":1}']);

    runCode(mockData);

    assertApi('updateConsentState').wasCalledWith({
      ad_storage: 'denied',
      ad_user_data: 'denied',
      ad_personalization: 'denied',
      analytics_storage: 'granted',
      functionality_storage: 'denied',
      personalization_storage: 'denied',
      security_storage: 'granted'
    });
- name: An unreadable consent cookie is ignored
  code: |-
    mock('injectScript', (url, onSuccess) => onSuccess());
    mock('getCookieValues', () => ['not json']);

    runCode(mockData);

    assertApi('updateConsentState').wasNotCalled();
    assertApi('gtmOnSuccess').wasCalled();
- name: Script failure reports a failure
  code: |-
    mock('injectScript', (url, onSuccess, onFailure) => onFailure());
    mock('getCookieValues', () => []);

    runCode(mockData);

    assertApi('gtmOnFailure').wasCalled();
    assertApi('gtmOnSuccess').wasNotCalled();
setup: |-
  const mockData = {
    publicKey: '3f2a9c1e-5b7d-4e8a-9c21-7d4e5f6a8b90',
    blockingMode: 'manual',
    defaultSettings: [],
    waitForUpdate: '500',
    adsDataRedaction: true,
    urlPassthrough: false,
    scriptUrl: 'https://cdn.berrycookie.com/bc.js'
  };


___NOTES___

BerryCookie consent management platform - https://berrycookie.com
