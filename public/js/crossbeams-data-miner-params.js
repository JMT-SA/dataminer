/* exported crossbeamsDataMinerParams */
// Behaviour for parameter entry page of Crossbeams DataMiner reports.

const crossbeamsDataMinerParams = {

  formId: '',
  reportNo: '',
  queryParams: {},
  current_values: [],

  removeQueryParamItem: function removeQueryParamItem(node) {
    const index = crossbeamsUtils.getListIndex(node);
    this.current_values.splice(index, 1);
    node.parentNode.removeChild(node);
  },

  queryItemAsText: function queryItemAsText(item) {
    let val = '';
    let valTo = '';
    if (item.op === 'is_null' || item.op === 'not_null') {
      val = '';
      valTo = '';
    } else {
      val = item.text;
      if (item.op === 'between') {
        valTo = ` AND ${item.textTo}`;
      } else {
        valTo = '';
      }
    }
    // return '<li style="list-style-type:none;">
    // <i class="fa fa-minus" style="cursor:pointer;color:red;"
    // onclick="removeQueryParamItem(this.parentNode)">
    // </i> ' + item.caption + ' ' + item.opText + ' ' + item.text;
    return `<li style="list-style-type:none;"><i class="fa fa-minus" style="cursor:pointer;color:red;" onclick="crossbeamsDataMinerParams.removeQueryParamItem(this.parentNode)"></i> ${item.caption} ${item.opText} ${val}${valTo}`;
  },

  querySelectionAsText: function querySelectionAsText(paramValues) {
    if (paramValues.length === 0) {
      return '<li style="list-style-type:none;">None selected</li>';
    }
    // var items = paramValues.map(function (entry) {
    //         return queryItemAsText(entry);
    // });
    const items = [];
    paramValues.forEach((item) => {
      items.push(crossbeamsDataMinerParams.queryItemAsText(item));
    });
    // for (i=0;i<paramValues.length;i++) {
    //     items.push(crossbeamsDataMinerParams.queryItemAsText(paramValues[i]));
    // }
    return items.join('');
  },

  containsObject: function containsObject(obj, list) {
    let foundMatch = false;
    list.forEach((item) => {
      if (item.col === obj.col && item.op === obj.op && item.val === obj.val &&
        item.valTo === obj.valTo) { // TODO: range of vals etc...
        foundMatch = true;
      }
    });
    return foundMatch;
  },

  displayParamsAsText: function displayParamsAsText() {
    let disp = '<ul>';
    disp += this.querySelectionAsText(this.current_values);
    disp += '</ul>';
    document.getElementById('param_display').innerHTML = disp;
  },

  operatorParmChange: function operatorParmChange(event) {
    const val1 = document.getElementById('qp_value');
    const val2 = document.getElementById('qp_value_to');
    switch (event.target.value) {
      case 'between':
        val1.style.display = '';
        val2.style.display = '';
        break;
      case 'is_null':
        val1.style.display = 'none';
        val2.style.display = 'none';
        break;
      case 'not_null':
        val1.style.display = 'none';
        val2.style.display = 'none';
        break;
      default:
        val1.style.display = '';
        val2.style.display = 'none';
    }
  },

  // choice object: {
  // col                        : query column name
  // op                         : operator (=,>...)
  // opText         : operater (is, greater than...)
  // val                        : selected/input value
  // valTo         : second value for date ranges
  // text          : selected value as text
  // (e.g. for dropdown this could differ from the value)
  // textTo        : second value for date ranges as text
  // }
  addQpFormParam: function addQpFormParam() {
    const choice = {};
    const valElem = document.getElementById('qp_value');
    const valElem2 = document.getElementById('qp_value_to');
    choice.col = document.getElementById('qp_column').value;
    choice.op = document.getElementById('qp_operator').value;
    choice.opText = document.getElementById('qp_operator').options[document.getElementById('qp_operator').selectedIndex].text;
    choice.val = valElem.value;
    choice.valTo = valElem2.value;
    const qp = this.queryParams[choice.col];
    if (qp.control_type === 'list') {
      choice.text = valElem.options[valElem.selectedIndex].text;
      choice.textTo = '';
    } else {
      choice.text = choice.val;
      choice.textTo = choice.valTo;
    }
    choice.caption = qp.caption;
    // if something other than is null or not null, 1st val must be present.
    // If between, both must be present...
    if (choice.op !== 'is_null' && choice.op !== 'not_null') {
      if (choice.val === '') {
        return false;
      }
    }
    if (choice.op === 'between') {
      if (choice.valTo === '') {
        return false;
      }
    }
    if (!crossbeamsDataMinerParams.containsObject(choice, this.current_values)) {
      this.current_values.push(choice);
      crossbeamsDataMinerParams.displayParamsAsText();
    }
    return true;
  },

  // Listeners for change of parameters and of operators.
  checkNode: function checkNode(addedNode) {
    let event = null;
    if (addedNode.nodeType === 1) {
      if (addedNode.matches('#qp_operator')) {
        addedNode.addEventListener('change', crossbeamsDataMinerParams.operatorParmChange);
        event = document.createEvent('HTMLEvents');
        event.initEvent('change', true, false);
        addedNode.dispatchEvent(event);
      }
    }
  },

  // Store current params
  // store limit, offset & current_values
  // key:...url, including report
  // val: {limit: ; offset: ; current_values: }
  // .. on submit form, store
  // .. on load, pass 'back' to init to reload params.
  // Maybe store previous n dm params?
  storeCurrentParams: function storeCurrentParams() {
    const limit = document.querySelector(`#${this.formId} input[name=limit]`).value;
    const offset = document.querySelector(`#${this.formId} input[name=offset]`).value;
    const stored = { limit, offset, paramValues: this.current_values };

    const key = crossbeamsLocalStorage.genStandardKey(this.reportNo);
    crossbeamsLocalStorage.setItem(key, stored);
  },

  loadCurrentParams: function loadCurrentParams() {
    const key = crossbeamsLocalStorage.genStandardKey(this.reportNo);
    let stored = null;
    if (crossbeamsLocalStorage.hasItem(key)) {
      // console.log('LOADING', this.reportNo, key);
      stored = crossbeamsLocalStorage.getItem(key);
      document.querySelector(`#${this.formId} input[name=limit]`).value = stored.limit;
      document.querySelector(`#${this.formId} input[name=offset]`).value = stored.offset;
      this.current_values = stored.paramValues;
      crossbeamsDataMinerParams.displayParamsAsText();
    }
  },

  buildReloadButton: function buildReloadButton() {
    const key = crossbeamsLocalStorage.genStandardKey(this.reportNo);
    if (crossbeamsLocalStorage.hasItem(key)) {
      document.querySelector('#reloadParams').style.display = '';
    }
  },

  applyDefaultValues: function applyDefaultValues(queryParams) {
    // for (qp in queryParams) { if (queryParams[qp].hasOwnProperty('default_value')) {
    // console.log(queryParams[qp]['default_value']); } }
    const choice = {};
    let elem = null;
    Object.keys(queryParams).forEach((qp) => {
      if (queryParams[qp].default_value) {
        // console.log(queryParams[qp]['default_value']);
        elem = queryParams[qp];
        choice.col = elem.column;
        choice.op = '=';
        choice.opText = 'is';
        choice.val = elem.default_value;
        choice.text = elem.default_value;
        choice.valTo = '';
        choice.textTo = '';
        choice.caption = elem.caption;
        this.current_values.push(choice);
      }
    });
    // for (qp in queryParams) {
    //     if (queryParams[qp].default_value) {
    //         // console.log(queryParams[qp]['default_value']);
    //         elem = queryParams[qp];
    //         choice.col = elem.column;
    //         choice.op = "=";
    //         choice.opText = "is";
    //         choice.val = elem.default_value;
    //         choice.text = elem.default_value;
    //         choice.valTo = "";
    //         choice.textTo = "";
    //         choice.caption = elem.caption;
    //         this.current_values.push(choice);
    //     }
    // }
  },

  init: function init(inFormId, inRptId, qprm) {
    let observer = null;
    this.formId = inFormId;
    this.reportNo = inRptId;
    this.queryParams = qprm;

    document.getElementById('select_param').addEventListener('change', (event) => {
      const val = event.target.value;
      let qp = null;
      let valInput = null;
      let inputType = null;
      const qpForm = document.getElementById('qp_form');
      if (val === '') {
        qpForm.innerHTML = '';
      } else {
        qp = crossbeamsDataMinerParams.queryParams[val];
        inputType = '';
        switch (qp.data_type) {
          case 'number':
            inputType = 'type="number"';
            break;
          case 'integer':
            inputType = 'type="number" pattern="\\d*"'; // Allow for minus sign?...
            break;
          case 'date':
            inputType = 'type="date"';
            break;
          case 'datetime':
            inputType = 'type="datetime-local"';
            break;

          // no default
        }

        if (qp.control_type === 'list') {
          valInput = `${crossbeamsUtils.makeSelect('qp_value', qp.list_values)}
            <input name="qp_value_to" id="qp_value_to" style="display:none" />`;
        } else if (qp.control_type === 'daterange') {
          valInput = `<input name="qp_value" id="qp_value" value="${
            (qp.default_value === null
              ? ''
                : qp.default_value)}" ${inputType} />
            <input name="qp_value_to" id="qp_value_to" ${inputType} />`;
        } else {
          valInput = `<input name="qp_value" id="qp_value" value="${
          (qp.default_value === null
            ? ''
              : qp.default_value)}" ${inputType} />
            <input name="qp_value_to" id="qp_value_to" style="display:none"${inputType} />`;
        }
        qpForm.innerHTML = `<form id="dForm" action="">
          <input type="hidden" id="qp_column" value="${qp.column}" />
          ${crossbeamsUtils.makeSelect('qp_operator', qp.operator)}
          ${valInput}
          <button type="button" class="pure-button pure-button"
          onclick="crossbeamsDataMinerParams.addQpFormParam()">
          <i class="fa fa-plus"></i></button></form>`;
      }
      // event.stopPropagation();
      // event.preventDefault();
    });

    // Apply default parameter values.
    crossbeamsDataMinerParams.applyDefaultValues(crossbeamsDataMinerParams.queryParams);

    crossbeamsDataMinerParams.displayParamsAsText();

    observer = new MutationObserver((mutations) => {
      mutations.forEach((node) => {
        node.addedNodes.forEach((addedNode) => {
          crossbeamsDataMinerParams.checkNode(addedNode);
        });
      });
      // for (i=0; i < mutations.length; i++){
      //     for (j=0; j < mutations[i].addedNodes.length; j++){
      //         crossbeamsDataMinerParams.checkNode(mutations[i].addedNodes[j]);
      //     }
      // }
    });

    observer.observe(document.documentElement, {
      childList: true,
      subtree: true,
    });
  },
};
