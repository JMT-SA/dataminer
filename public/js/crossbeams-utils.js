/* exported crossbeamsUtils */
// General utility functions for Crossbeams.

const crossbeamsUtils = {

  // Toggle the visibility of en element in the DOM:
  // Optionally pass in a button to add the pure-button-active class (Pure.css)
  toggleVisibility: function toggleVisibility(id, button) {
    const e = document.getElementById(id);

    if (e.style.display === 'block') {
      e.style.display = 'none';
      if (button !== undefined) {
        button.classList.remove('pure-button-active');
      }
    } else {
      e.style.display = 'block';
      if (button !== undefined) {
        button.classList.add('pure-button-active');
      }
    }
  },

  /**
   * confirm() Shows a SweetAlert2 dialog asking the user to confirm or cancel.
   * @param ...
   */
  confirm: function confirm({ prompt, title, okFunc, cancelFunc }) {
    // console.log(title);
    swal({
      title: title === undefined ? '' : title,
      text: prompt,
      type: 'warning',
      showCancelButton: true }).then(okFunc, cancelFunc).catch(swal.noop);
  },

  getCharCodeFromEvent: function getCharCodeFromEvent(evt) {
    const event = evt || window.event;
    return (event.which === 'undefined')
      ? event.keyCode
      : event.which;
  },

  isCharNumeric: function isCharNumeric(charStr) {
    return !!(/\d/.test(charStr));
  },

  isKeyPressedNumeric: function isKeyPressedNumeric(event) {
    const charCode = this.getCharCodeFromEvent(event);
    const charStr = String.fromCharCode(charCode);
    return this.isCharNumeric(charStr);
  },

  // Make a select tag using an array for the options.
  // The Array can be an Array of Arrays too.
  makeSelect: function makeSelect(name, arr) {
    // var sel = '<select id="' + name + '" name="' + name + '">';
    let sel = `<select id="${name}" name="${name}">`;
    arr.forEach((item) => {
      if (item.constructor === Array) {
        // sel += '<option value="' + (item[1] || item[0]) + '">' + item[0] + '</option>';
        sel += `<option value="${(item[1] || item[0])}">${item[0]}</option>`;
      } else {
        // sel += '<option value="' + item + '">' + item + '</option>';
        sel += `<option value="${item}">${item}</option>`;
      }
    });
    sel += '</select>';
    return sel;
  },

  // Adds a parameter named "json_var" to a form
  // containing a stringified version of the passed object.
  addJSONVarToForm: function addJSONVarToForm(formId, jsonVar) {
    const form = document.getElementById(formId);
    const element1 = document.createElement('input');
    element1.type = 'hidden';
    element1.value = JSON.stringify(jsonVar);
    element1.name = 'json_var';
    form.appendChild(element1);
  },

  // Return the index of an LI tag in a UL/OL list.
  getListIndex: function getListIndex(node) {
    const childs = node.parentNode.children; // childNodes;
    let i = 0;
    let index;
    Array.from(childs).forEach((child) => {
      i += 1;
      if (node === child) {
        index = i;
      }
    });
    return index;
  },

};

