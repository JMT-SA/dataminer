module.exports = {
  "extends": "airbnb-base",
  "plugins": [
    "import"
  ],
  "parserOptions": {
    "sourceType": 'script',
    "ecmaFeatures": {
      "impliedStrict": true
    }
  },
  "rules": {
    "no-param-reassign": [ "error", { "props": false } ],
    "valid-jsdoc": "error"
  },
  "env": {
    "browser": true,
    "jquery": true,
  },
  "globals": {
    "swal": false,
    "agGrid": false,
    "crossbeamsUtils": false,
    "crossbeamsLocalStorage": false
  }
};