var trs=document.getElementsByTagName('tr');

for(var i=0; i<trs.length;i++){

   if(i%2==0){

  trs[i].style.background="#d2ebf9";

}else{
 trs[i].style.background="#abcdef";
 }
   }