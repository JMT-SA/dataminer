/* exported crossbeamsLocalStorage */

// Wrapper around browser storage (auto JSON stringify & parse).
const crossbeamsLocalStorage = {
  // storageAdaptor: sessionStorage,
  storageAdaptor: localStorage,

  // Thanks Angus! - http://goo.gl/GtvsU
  toType: function toType(obj) {
    return ({}).toString.call(obj).match(/\s([a-z|A-Z]+)/)[1].toLowerCase();
  },

  hasItem: function hasItem(key) {
    return this.storageAdaptor.getItem(key) !== null;
  },

  getItem: function getItem(key) {
    let item = this.storageAdaptor.getItem(key);

    try {
      item = JSON.parse(item);
    } catch (e) {
      // Ignore
    }

    return item;
  },

  setItem: function setItem(key, inValue) {
    let value = inValue;
    const type = this.toType(value);

    if (/object|array/.test(type)) {
      value = JSON.stringify(value);
    }

    this.storageAdaptor.setItem(key, value);
  },

  removeItem: function removeItem(key) {
    this.storageAdaptor.removeItem(key);
  },

  genStandardKey: function genStandardKey(suffix) {
    const rx = new RegExp('/\\d+$');
    if (suffix === undefined) {
      return window.location.pathname.replace(rx, '');
    }
    return `${window.location.pathname.replace(rx, '')}|${suffix}`;
  },
};
