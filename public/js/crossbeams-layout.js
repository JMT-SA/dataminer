// for equiv of $ready() -- place this code at end of <body> or use: document.addEventListener('DOMContentLoaded', fn, false);
function load_section(elem)
{
   var xhr = new XMLHttpRequest();
   var url = elem.dataset['crossbeams_callback_section'];
   var content_div = elem.querySelectorAll('.content-target')[0]

   xhr.onreadystatechange = function() {
        if (xhr.readyState == 4 && xhr.status == 200)
        {
           content_div.classList.remove('content-loading');
           content_div.innerHTML = xhr.responseText;
        }
    };

    xhr.open("GET", url, true); // true for asynchronous
    xhr.send(null);

}
var elements = document.querySelectorAll("section");
for (var i = 0; i < elements.length; i++) {
  if (elements[i].dataset['crossbeams_callback_section'] !== undefined) {
    load_section(elements[i]);
  }
}
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

