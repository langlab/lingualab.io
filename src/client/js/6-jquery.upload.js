$.upload = function(url, data, settings){    
  var fd = new FormData;
  
  if ( data instanceof File )
    data = {"file": data}
  
  for ( var key in data )
    fd.append(key, data[key]);
  
  // Last argument can be success callback
  if ( typeof settings == "function" ) {
    settings = {success: settings};
  }
  
  settings.url  = url;
  settings.data = fd;
  settings = $.extend({}, defaults, settings);
  
  return $.ajax(settings);
};

(function($){
  function dragEnter(e) {
    $(e.target).addClass("dragOver");
    e.stopPropagation();
    e.preventDefault();
    return false;
  };
  
  function dragOver(e) {
    e.originalEvent.dataTransfer.dropEffect = "copy";
    e.stopPropagation();
    e.preventDefault();
    return false;    
  };
  
  function dragLeave(e) {
    $(e.target).removeClass("dragOver");
    e.stopPropagation();
    e.preventDefault();
    return false;
  };
      
  $.fn.dropArea = function(){
    this.bind("dragenter", dragEnter).
         bind("dragover",  dragOver).
         bind("dragleave", dragLeave);
    return this;
  };
  
  $(function(){
    $(document.body).bind("dragover", function(e){
      e.stopPropagation();
      e.preventDefault();
      return false
    });
  });
})(jQuery);
