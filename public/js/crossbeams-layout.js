// for equiv of $ready() -- place this code at end of <body> or use:
// document.addEventListener('DOMContentLoaded', fn, false);
(function crossbeamsLayout() {
  function loadSection(elem) {
    const xhr = new XMLHttpRequest();
    const url = elem.dataset.crossbeams_callback_section;
    const contentDiv = elem.querySelectorAll('.content-target')[0];

    xhr.onreadystatechange = () => {
      if (xhr.readyState === 4 && xhr.status === 200) {
        contentDiv.classList.remove('content-loading');
        contentDiv.innerHTML = xhr.responseText;
      }
    };
    xhr.open('GET', url, true); // true for asynchronous
    xhr.send(null);
  }
  const elements = document.querySelectorAll('section');
  elements.forEach((element) => {
    if (element.dataset.crossbeams_callback_section !== undefined) {
      loadSection(element);
    }
  });

  // Prevent multiple clicks of submit buttons.
  function preventMultipleSubmits() {
    this.dataset.enableWith = this.value;
    this.value = this.dataset.disableWith;
    this.classList.remove('dim');
    this.classList.add('o-50');
    window.setTimeout('this.disabled=true', 0); // Disable the button with a delay so the form still submits...
  }

  // // Remove disabled state from button
  // function revertDisabledButton(element) {
  //   element.disabled = false;
  //   element.value = element.dataset.enableWith;
  //   element.classList.add('dim');
  //   element.classList.remove('o-50');
  // }

  // Assign click handler to buttons that need to be disabled.
  document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('[data-disable-with]').forEach((element) => {
      element.onclick = preventMultipleSubmits;
    });
  });
}());
// CODE FROM HERE...
// This is an alternative way of loading sections...
// (js can be in head of page)
// ====================================================
// checkNode = function(addedNode) {
//   if (addedNode.nodeType === 1){
//     if (addedNode.matches('section[data-crossbeams_callback_section]')){
//      load_section(addedNode);
//       //SmartUnderline.init(addedNode);
//     }
//   }
// }
// var observer = new MutationObserver(function(mutations){
//   for (var i=0; i < mutations.length; i++){
//     for (var j=0; j < mutations[i].addedNodes.length; j++){
//       checkNode(mutations[i].addedNodes[j]);
//     }
//   }
// });
//
// observer.observe(document.documentElement, {
//   childList: true,
//   subtree: true
// });
// ====================================================
// ...TO HERE.
