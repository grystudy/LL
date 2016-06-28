function showToolTip(title,msg,evt){
    if (evt) {
        var url = evt.target;
       }
    else {
        evt = window.event;
        var url = evt.srcElement;
     }

   var xPos = evt.clientX;
   var yPos = evt.clientY;

   var toolTip = document.getElementById("toolTip");
   //toolTip.innerHTML = "<h1>"+title+"</h1><p>"+msg+"</p>";
   if(msg.length<15)return;
   toolTip.innerHTML = "<div>"+msg+"</div>";
   toolTip.style.top = parseInt(yPos)+2 + "px";
   toolTip.style.left = parseInt(xPos)+2 + "px";
   toolTip.style.visibility = "visible";
   
}

function hideToolTip(){
   var toolTip = document.getElementById("toolTip");
   toolTip.style.visibility = "hidden";
}