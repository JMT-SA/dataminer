
// Object to keep track of the grids in a page - so they can be looked up by div id.
/**
 * In-browser store of grids on the page.
 * @namespace
 */
const crossbeamsGridStore = {
  gridStore: {},

  /**
   * Add a grid to the store.
   * @param {string} gridId - the id of the grid div element.
   * @param {object} gridOptions - reference to the grid options object.
   * @returns {void}
   */
  addGrid: function addGrid(gridId, gridOptions) {
    this.gridStore[gridId] = gridOptions;
  },

  /**
   * Retrieve a grid from the store.
   * @param {string} gridId - the id of the grid div element.
   * @returns {agGrid} - reference to the grid.
   */
  getGrid: function getGrid(gridId) {
    return this.gridStore[gridId];
  },

  /**
   * Remove a grid from the store.
   * @param {string} gridId - the id of the grid div element.
   * @returns {void}
   */
  removeGrid: function removeGrid(gridId) {
    this.gridStore[gridId].api.destroy();
    delete this.gridStore[gridId];
  },

  /**
   * List of grid ids in the store.
   * @returns {string} - a list of the grid ids.
   */
  listGridIds: function listGridIds() {
    const lst = [];
    this.gridStore.forEach((gridId) => {
      lst.push(gridId);
    });
    // for (gridId in this.gridStore) {
    //   lst.push(gridId);
    // }
    return lst.join(', ');
  },
};

/**
 * Handle various events related to interactions with the grid.
 * @namespace
 */
const crossbeamsGridEvents = {
  /**
   * Export a grid to a csv file.
   * @param {string} gridId - the DOM id of the grid.
   * @param {string} fileName - the name to be given to the exported file.
   * @returns {void}
   */
  csvExport: function csvExport(gridId, fileName) {
    const colKeys = [];
    let params = {};

    // Get visible columns that do not explicitly have 'suppressCsvExport' set.
    const gridOptions = crossbeamsGridStore.getGrid(gridId);
    const visibleCols = gridOptions.columnApi.getAllDisplayedColumns();

    visibleCols.forEach((col) => {
      if (!col.colDef.suppressCsvExport || col.colDef.suppressCsvExport === false) {
        colKeys.push(col.colId);
      }
    });
    // for (i = 0, len = visibleCols.length; i < len; i++) {
    //   if (visibleCols[i].colDef.suppressCsvExport &&
    //   visibleCols[i].colDef.suppressCsvExport === true) {
    //   } else {
    //     colKeys.push(visibleCols[i].colId);
    //   }
    // }

    params = {
      fileName,
      columnKeys: colKeys, // Visible, non-suppressed columns.
      // skipHeader: true,
      // skipFooters: true,
      // skipGroups: true,
      // allColumns: true,
      // suppressQuotes: true,
      // onlySelected: true,
      // columnSeparator: ';'
    };

    // Ensure long numbers are exported as strings.
    params.processCellCallback = (parms) => {
      let testStr = '';
      // If HTML entities are a problem...
      // parms.value.replace(/&amp;/g, "&")
      // .replace(/\\&quot;/g, "\"")
      // .replace(/&quot;/g, "\"")
      // .replace(/&gt;/g, ">").replace(/&#x2F;/g, "/").replace(/&lt;/g, "<");

      if (parms.value) {
        testStr = `${parms.value}`;
        if (testStr.length > 12 && !isNaN(testStr) && !testStr.includes('.')) {
          return `'${testStr}`;
        }
      }
      return parms.value;
    };

    gridOptions.api.exportDataAsCsv(params);
  },

  /**
   * Show/hide the grid's tool panel.
   * @param {string} gridId - the DOM id of the grid.
   * @returns {void}
   */
  toggleToolPanel: function toggleToolPanel(gridId) {
    const gridOptions = crossbeamsGridStore.getGrid(gridId);
    const isShowing = gridOptions.api.isToolPanelShowing();
    gridOptions.api.showToolPanel(!isShowing);
  },

  /**
   * Show a printable version of the grid.
   * @param {string} gridId - the DOM id of the grid.
   * @param {string} gridUrl - the url to populate the grid.
   * @returns {void}
   */
  printAGrid: function printAGrid(gridId, gridUrl) {
    const dispSetting = 'toolbar=yes,location=no,directories=yes,menubar=yes,';
    // dispSetting += 'scrollbars=yes,width=650, height=600, left=100, top=25';
    window.open(`/print_grid?grid_url=${encodeURIComponent(gridUrl)}`, 'printGrid', dispSetting);
  },

  /**
   * Filter a grid using a quick search across all columns in all rows.
   * @param {event} event - a keypress event.
   * @returns {void}
   */
  quickSearch: function quickSearch(event) {
    const gridOptions = crossbeamsGridStore.getGrid(event.target.dataset.gridId);
    // clear on Esc
    if (event.which === 27) {
      event.target.value = '';
    }
    gridOptions.api.setQuickFilter(event.target.value);
  },

  // setFilterChangeEvent: function(gridId) {
  //   var gridOptions;
  //
  //   gridOptions = crossbeamsGridStore.getGrid(gridId);
  //   gridOptions.api.afterFilterChanged();
  //   //.api.rowModel.rootNode.childrenAfterFilter.length
  //
  // }

  /**
   * Show the results of a filter change (no rows of total displayed).
   * FIXME: Not yet working.
   * @param {string} gridId - the DOM id of the grid.
   * @returns {void}
   */
  showFilterChange: function showFilterChange(gridId) {
    let filterLength = 0;
    const gridOptions = crossbeamsGridStore.getGrid(gridId);
    if (gridOptions.api.rowModel.rootNode.childrenAfterFilter) {
      filterLength = gridOptions.api.rowModel.rootNode.childrenAfterFilter.length;
    }
    // console.log('onAfterFilterChanged', filterLength, gridId);
  },

  /**
   * Show a prompt asking the user to confirm an action from a link in a grid.
   * @param {element} target - the link.
   * @returns {void}
   */
  promptClick: function promptClick(target) {
    // const target = event.target;
    const prompt = target.dataset.prompt;
    const url = target.dataset.url;
    const method = target.dataset.method;

    swal({
      title: prompt,
      type: 'warning',
      showCancelButton: true,
    }).then(() => {
      document.body.innerHTML += `<form id="dynForm" action="${url}"
        method="post"><input name="_method" type="hidden" value="${+method}" /></form>`;
      document.getElementById('dynForm').submit();
    });
    // TODO: make call via AJAX & reload grid? Or http to server to figure it out?.....
    // ALSO: disable link automatically while call is being processed...
    event.stopPropagation();
    event.preventDefault();
  },
};

const crossbeamsGridFormatters = {
  testRender: function testRender(params) {
    return `<b>${params.value.toUpperCase()}</b>`;
  },

  menuActionsRenderer: function menuActionsRenderer(params) {
    // params value should always be an array.
    // if empty, render ''
    // console.log('parm', params);
    let valueObj = params.value;
    if (valueObj === undefined || valueObj === null) {
      valueObj = params.valueGetter();
    }
    // console.log('vO', valueObj);
    if (valueObj.length === 0) { return ''; }
    const items = [];
    let urlComponents;
    let url;
    valueObj.forEach((item) => {
      urlComponents = item.url.split('$');
      url = '';
      urlComponents.forEach((cmp, index) => {
        if (index % 2 === 0) {
          url += cmp;
        } else {
          url += params.data[item[cmp]];
        }
      });
      // console.log('t1',item.title);
      items.push({ name: item.text,
        url,
        prompt: item.prompt,
        method: item.method,
        title: item.title,
      });
    });
    // console.log(JSON.stringify(items));
    return `<button class='grid-context-menu' data-row='${JSON.stringify(items)}'>list</button>`;
  },

  // Return a number with thousand separator and at least 2 digits after the decimal.
  numberWithCommas2: function numberWithCommas2(params) {
    let x = params.value;
    let parts = [];
    if (typeof x === 'string') { x = parseFloat(x); }
    if (isNaN(x)) { return ''; }
    x = Math.round((x + 0.00001) * 100) / 100; // Round to 2 digits if longer.
    parts = x.toString().split('.');
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    if (parts[1] === undefined || parts[1].length === 0) { parts[1] = '00'; }
    if (parts[1].length === 1) { parts[1] += '0'; }
    return parts.join('.');
  },

  // Return a number with thousand separator and at least 4 digits after the decimal.
  numberWithCommas4: function numberWithCommas4(params) {
    let x = params.value;
    let parts = [];
    if (typeof x === 'string') { x = parseFloat(x); }
    if (isNaN(x)) { return ''; }
    x = Math.round((x + 0.0000001) * 10000) / 10000; // Round to 4 digits if longer.
    parts = x.toString().split('.');
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    if (parts[1] === undefined || parts[1].length === 0) { parts[1] = '0000'; }
    while (parts[1].length < 4) { parts[1] += '0'; }
    return parts.join('.');
  },

  booleanFormatter: function booleanFormatter(params) {
    if (params.value === '') { return ''; }
    if (params.value === 't' || params.value === 'true' || params.value === 'y' || params.value === 1) {
      return '<span class="ac_icon_check">&nbsp;</span>';
    }
    return '<span class="ac_icon_uncheck">&nbsp;</span>';
  },

  hrefInlineFormatter: function hrefInlineFormatter(params) {
    // var rainPerTenMm = params.value / 10;
    return `<a href="/books/${params.value}/edit">edit</a>`;
  },

  hrefSimpleFormatter: function hrefSimpleFormatter(params) {
    const val = params.value;
    return `<a href="${val.split('|')[0]}">${val.split('|')[1]}</a>`;
  },

  // Creates a link that when clicked prompts for a yes/no answer.
  // Column value is in the format "url|linkText|prompt|method".
  // Only url and linkText are required.
  hrefPromptFormatter: function hrefPromptFormatter(params) {
    let url = '';
    let linkText = '';
    let prompt;
    let method;
    [url, linkText, prompt, method] = params.value.split('|');
    prompt = prompt || 'Are you sure?';
    method = (method || 'post').toLowerCase();
    return `<a href='#' data-prompt="${prompt}" data-method="${method}" data-url="${url}"
    onclick="crossbeamsGridEvents.promptClick();">${linkText}</a>`;
  },
};

// function to act as a class
function NumericCellEditor() {
}

// gets called once before the renderer is used
NumericCellEditor.prototype.init = (params) => {
  // create the cell
  this.eInput = document.createElement('input');
  this.eInput.value = crossbeamsUtils.isCharNumeric(params.charPress)
    ? params.charPress
    : params.value;

  const that = this;
  this.eInput.addEventListener('keypress', (event) => {
    if (!crossbeamsUtils.isKeyPressedNumeric(event)) {
      that.eInput.focus();
      if (event.preventDefault) event.preventDefault();
    }
  });

  // only start edit if key pressed is a number, not a letter
  const charPressIsNotANumber = params.charPress && ('1234567890'.indexOf(params.charPress) < 0);
  this.cancelBeforeStart = charPressIsNotANumber;
};

// gets called once when grid ready to insert the element
NumericCellEditor.prototype.getGui = () => this.eInput;

// focus and select can be done after the gui is attached
NumericCellEditor.prototype.afterGuiAttached = () => {
  this.eInput.focus();
};

// returns the new value after editing
NumericCellEditor.prototype.isCancelBeforeStart = () => this.cancelBeforeStart;

// example - will reject the number if it contains the value 007
// - not very practical, but demonstrates the method.
NumericCellEditor.prototype.isCancelAfterEnd = () => {
  // var value = this.getValue();
  // return value.indexOf('007') >= 0;
};

// returns the new value after editing
NumericCellEditor.prototype.getValue = () => {
  if (this.eInput.value === '') {
    return '';
  }
  return parseInt(this.eInput.value, 10);
};

// any cleanup we need to be done here
NumericCellEditor.prototype.destroy = () => {
  // but this example is simple, no cleanup, we could  even leave this method out as it's optional
};

// if true, then this editor will appear in a popup
  // and we could leave this method out also, false is the default
NumericCellEditor.prototype.isPopup = () => false;


(function crossbeamsGridLoader() {
  // var onBtExport;
  const translateColDefs = function translateColDefs(columnDefs) {
    // console.log(columnDefs);
    const newColDefs = [];
    let newCol = {};
    // let fn = null;
    // for (i = 0, len = columnDefs.length; i < len; i++) {
    columnDefs.forEach((col) => {
      // col = columnDefs[i];
      newCol = {};
      // for(attr in col) {
      Object.keys(col).forEach((attr) => {
        if (attr === 'cellRenderer') {
          // fn = window[col[attr]];
          // newCol[attr] = fn;
          // newCol[attr] = eval(col[attr]);
          if (col[attr] === 'crossbeamsGridFormatters.testRender') {
            newCol[attr] = crossbeamsGridFormatters.testRender;
          }
          if (col[attr] === 'crossbeamsGridFormatters.menuActionsRenderer') {
            newCol[attr] = crossbeamsGridFormatters.menuActionsRenderer;
          }
          if (col[attr] === 'crossbeamsGridFormatters.numberWithCommas2') {
            newCol[attr] = crossbeamsGridFormatters.numberWithCommas2;
          }
          if (col[attr] === 'crossbeamsGridFormatters.numberWithCommas4') {
            newCol[attr] = crossbeamsGridFormatters.numberWithCommas4;
          }
          if (col[attr] === 'crossbeamsGridFormatters.booleanFormatter') {
            newCol[attr] = crossbeamsGridFormatters.booleanFormatter;
          }
          if (col[attr] === 'crossbeamsGridFormatters.hrefInlineFormatter') {
            newCol[attr] = crossbeamsGridFormatters.hrefInlineFormatter;
          }
          if (col[attr] === 'crossbeamsGridFormatters.hrefSimpleFormatter') {
            newCol[attr] = crossbeamsGridFormatters.hrefSimpleFormatter;
          }
          if (col[attr] === 'crossbeamsGridFormatters.hrefPromptFormatter') {
            newCol[attr] = crossbeamsGridFormatters.hrefPromptFormatter;
          }
        } else if (attr === 'cellEditor') {
          // console.log('edit');
          if (col[attr] === 'NumericCellEditor') {
            // console.log('edit - NUM');
            newCol[attr] = NumericCellEditor;
          } else {
            // Ignore other editor types   TODO: ????
          }
        } else {
          newCol[attr] = col[attr];
        }
      });
      newColDefs.push(newCol);
    });
    return newColDefs;
  };

  const loadGrid = function loadGrid(grid, gridOptions) {
    const url = grid.getAttribute('data-gridurl');
    const httpRequest = new XMLHttpRequest();
    httpRequest.open('GET', url);
    httpRequest.send();
    // return httpRequest.onreadystatechange = () => {
    httpRequest.onreadystatechange = () => {
      let httpResult = null;
      let newColDefs = null;
      if (httpRequest.readyState === 4 && httpRequest.status === 200) {
        httpResult = JSON.parse(httpRequest.responseText);
        newColDefs = translateColDefs(httpResult.columnDefs);
        gridOptions.api.setColumnDefs(newColDefs);
        gridOptions.api.setRowData(httpResult.rowDefs);
      }
    };
  };

  // document.addEventListener(eventName, eventHandler);
  document.addEventListener('DOMContentLoaded', () => {
    let grid = null;
    let gridOptions = null;
    let len = null;
    // let _results = null;
    let gridId = null;
    let forPrint = false;
    let i = null;
    const grids = document.querySelectorAll('[data-grid]');
    // _results = [];
    for (i = 0, len = grids.length; i < len; i += 1) {
      grid = grids[i];
      gridId = grid.getAttribute('id');
      forPrint = grid.dataset.gridPrint;
      // lookup of grid ids? populate here and clear when grid unloaded...
      gridOptions = {
        columnDefs: null,
        rowDefs: null,
        enableColResize: true,
        enableSorting: true,
        enableFilter: true,
        suppressScrollLag: true,
        enableRangeSelection: true,
        enableStatusBar: true,
        suppressAggFuncInHeader: true,
        // onAfterFilterChanged: function() {
        // console.log('onAfterFilterChanged',
        // this.api.rowModel.rootNode.childrenAfterFilter.length, gridId);}
        // onAfterFilterChanged: crossbeamsGridEvents.showFilterChange(gridId)
        // suppressCopyRowsToClipboard: true
        // quickFilterText: 'fred'
      };
      if (forPrint) {
        gridOptions.forPrint = true;
        gridOptions.enableStatusBar = false;
      }

      // new agGrid.Grid(grid, gridOptions);
      new agGrid.Grid(grid, gridOptions);
      crossbeamsGridStore.addGrid(gridId, gridOptions);
      gridOptions.onAfterFilterChanged = crossbeamsGridEvents.showFilterChange(gridId);
      // _results.push(loadGrid(grid, gridOptions));
      loadGrid(grid, gridOptions);
    }
    // return _results;
  });
}).call(this);

$(() => {
  $.contextMenu({
    selector: '.grid-context-menu',
    trigger: 'left',
    build: ($trigger, e) => {
      // this callback is executed every time the menu is to be shown
      // its results are destroyed every time the menu is hidden
      // e is the original contextmenu event, containing e.pageX and e.pageY (amongst other data)
      // var url_components;
      // var url;
      const row = e.target.dataset.row;
      const items = {};
      JSON.parse(row).forEach((item) => {
        items[item.name] = {
          name: item.name,
          url: item.url,
          prompt: item.prompt,
          method: item.method,
          title: item.title,
        };
      });

      return {
        // callback: (key, options) => {
        callback: (key) => {
          const item = items[key];
          const caller = () => {
            if (item.method === undefined) {
              window.location = item.url;
            } else {
              document.body.innerHTML += `<form id="dynForm" action="${item.url}" method="post">
                <input name="_method" type="hidden" value="${item.method}" /></form>`;
              document.getElementById('dynForm').submit();
            }
          };
          if (item.prompt !== undefined) {
            crossbeamsUtils.confirm({
              prompt: item.prompt,
              okFunc: caller,
              title: item.title,
            });
          } else {
            caller();
          }
        },
        items,
      };
    },
  });
});
