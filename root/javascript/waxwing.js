var IMG_NAME;
var IMG_TYPE;
var IMG_DATA;
var IMG_ORIENTATION = 1;

	require(["dojo/dom", "dojo/domReady!"], function(dom){
		// var MAX_HEIGHT = 100;
		var MAX_HEIGHT = 640;
		var target = dom.byId("fileselect");
		var preview = dom.byId("preview");
		var canvas = dom.byId("canvas");

                document.getElementById("mysubmit").disabled = true;

		var render = function(src){

			var img = new Image();
			img.onload = function(){
                   
                            if ( IMG_TYPE == "image/jpeg" ) {  
                                EXIF.getData(img, function() {
                                    // alert(EXIF.pretty(this));
                                    IMG_ORIENTATION = EXIF.getTag(img, "Orientation");
                                    if ( isNaN(IMG_ORIENTATION) ) {
                                        IMG_ORIENTATION = 1;
                                    }
                                });
                            }
                                if ( img.height > MAX_HEIGHT || img.width > MAX_HEIGHT ) {
                                    if ( img.height > img.width ) {
                                        img.width  = ( MAX_HEIGHT / img.height ) * img.width;
                                        img.height = MAX_HEIGHT;
                                    } else {
                                        img.height = ( MAX_HEIGHT / img.width ) * img.height;
                                        img.width  = MAX_HEIGHT;
                                    } 
                                }
                   		var ctx = canvas.getContext("2d");
				ctx.clearRect(0, 0, canvas.width, canvas.height);
				preview.style.width = img.width + "px";
				preview.style.height = img.height + "px";
				canvas.width = img.width;
				canvas.height = img.height;
                                // alert('ch= ' + canvas.height + ' cw= ' + canvas.width);
				ctx.drawImage(img, 0, 0, img.width, img.height);
                                // last val = resolution quality. 
                                IMG_DATA = encodeURIComponent(document.getElementById("canvas").toDataURL("image/jpeg", 0.8));
                                document.getElementById("mysubmit").disabled = false;
			};
			img.src = src;
		};

		var readImage = function(imgFile){
			if(!imgFile.type.match(/image.*/)){
				console.log("The dropped file is not an image: ", imgFile.type);
				return;
			}

                        IMG_NAME = imgFile.name;
                        IMG_TYPE = imgFile.type;

			var reader = new FileReader();
			reader.onload = function(e){
				render(e.target.result);
			};
			reader.readAsDataURL(imgFile);
		};
		target.addEventListener("change", function(e){
			e.preventDefault(); 
			readImage(e.target.files[0] || e.dataTransfer.files[0]);
		}, true);
	});

	// getElementById
	function $id(id) {
		return document.getElementById(id);
	}

	// output information
	function Output(msg) {
		var m = $id("messages");
		m.innerHTML = msg + m.innerHTML;
	}

function myupload_dojo () {
require(["dojo/request/xhr"], function(xhr, id){

        var author_name  = getCookie('waxwingauthor_name');
        var session_id   = getCookie('waxwingsession_id');

        if ( !IMG_DATA.length ) {
            alert("Image is not ready to upload. Try again.");
        } 

        var image_text = document.getElementById('imagetext').value;

        var myRequest = {         // create a request object that can be serialized via JSON
            author:           author_name,
            session_id:       session_id,
            imagename:        IMG_NAME,
            imagetype:        IMG_TYPE,
            imageorientation: IMG_ORIENTATION,
            imagetext:        image_text,
            imagedata:        IMG_DATA
        };

        var json_str = JSON.stringify(myRequest);

        var m = $id("uploadmessage");
        m.innerHTML = " <strong>... uploading ...</strong>";

    xhr.post("http://waxwing.soupmode.com/addimagejson", {
        data: { json_str: json_str },
        handleAs: "json" 
    }).then(
        function(data){
            console.log("The server returned: ", data);

            // Output("<p><strong>" + IMG_NAME + "</strong> uploaded.</p>\n" + data.html);
            Output(
                      "<p><strong>" + IMG_NAME + 
                      "</strong> uploaded on " + data.formatted_updated_at + ".</p>\n<p><a href=\"" + 
                      data.image_url + "\"><img src=\"" + 
                      data.image_url + "\"></a>\n<br /><div class=\"imagetext\">" + 
                      data.html + "</div><br /></p><br />\n"
                 );
            document.getElementById('imagetext').value=''; 
            document.getElementById('fileselect').value=''; 
            m.innerHTML = " ";
            document.getElementById("mysubmit").disabled = true;
        },
        function(error){
            var obj = JSON.parse(error.response.text);
            console.log("An error occurred: " + obj.user_message + " " + obj.system_message);
            document.getElementById("mysubmit").disabled = true;
            m.innerHTML = " <strong>... An Error Occurred ...</strong> " + obj.user_message + " " + obj.system_message;
        }
    );

function getCookie(c_name) {
        var c_value = document.cookie;
        var c_start = c_value.indexOf(" " + c_name + "=");
        if (c_start == -1) {
            c_start = c_value.indexOf(c_name + "=");
        }
        if (c_start == -1) {
            c_value = null;
        }
        else {
            c_start = c_value.indexOf("=", c_start) + 1;
            var c_end = c_value.indexOf(";", c_start);
            if (c_end == -1) {
                c_end = c_value.length;
            }
            c_value = unescape(c_value.substring(c_start,c_end));
        }
        return c_value;
    }

});
}
