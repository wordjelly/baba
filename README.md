##Instructions to scrape medicines:

###Copy and Paste the following into the console:


```
var textFile = null,
  makeTextFile = function (text) {
    var data = new Blob([text], {type: 'text/plain'});

    // If we are replacing a previously generated file we need to
    // manually revoke the object URL to avoid memory leaks.
    if (textFile !== null) {
      window.URL.revokeObjectURL(textFile);
    }

    textFile = window.URL.createObjectURL(data);

    // returns a URL you can use as a href
    return textFile;
  };

var parse_page = function(){$("tr.cursor").each(function(index,obj){
    var med_name = $(obj).find(".searchResultProductName").first().text();
    var med_details = $(obj).text().replace(/\t|\n/,''); 
    med_details = med_details.replace(/\n|\t|\\t|\\n|\\\t|\\\n/,'');                                                  
    if(localStorage.getItem("medicines") != null){                                                  var curr_medicines = JSON.parse(localStorage.getItem("medicines"));                     curr_medicines[med_name] = med_details;
              localStorage.setItem("medicines",JSON.stringify(curr_medicines));             }                                                                                       else{                                                                                           var curr_medicines = {};                                                               curr_medicines[med_name] = med_details;
            localStorage.setItem("medicines",JSON.stringify(curr_medicines));                }                                           
})};

var timesRun = 0;
var interval = setInterval(function(){
    timesRun += 1;
    $(".left.pagenationicnryt").first().trigger("click");
    if(timesRun === 4){
        clearInterval(interval);
        makeTextFile(localStorage.getItem("medicines"));
    }
    parse_page();
}, 3000); 
```

It will run the code 4 times, and then print out a url in the console.
Copy that exact line into a new window, and visit it.
There you will get a JSON object, key -> medicine name, value -> medicine details.
Knock off the tabs and new lines, in ruby or something, I could not get rid of it in java.
