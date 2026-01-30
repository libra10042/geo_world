<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%response.setHeader("Access-Control-Allow-Origin","test.com"); %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta content="IE=edge" http-equiv="X-UA-Compatible">
    <title>WFS Vworld Test</title>

    <style type="text/css">
      html, body, #map { margin: 0; padding: 0; width: 100%; height: 800px; }
    
		.map:-webkit-full-screen { 
			height: 100%; 
			margin: 0; 
		}
		.map:-ms-fullscreen { 
			height: 100%; 
		}
		.map:fullscreen { 
			height: 100%; 
		}
		.map .ol-rotate { 
			top: 3em;
		}
    
    
    </style>
    
<link rel="shortcut icon" href="#">
<link rel="stylesheet" type="text/css" href="/openlayers/ol.css">
<script src="/jquery-3.7.1.min.js"></script>
<script src="/jquery.ajax-cross-origin.min.js"></script>
<script src="/openlayers/dist/ol.js"></script>

<script type="text/javascript">

var map;
const key = "44E49856-479B-36C0-A0F1-4A7EF3190015";

$(document).ready(function() {
	initMap();
});

function initMap() {
	
	let vectorSource = new ol.source.Vector({
  	  format : new ol.format.GML3(),
  	  loader: function(extent, resolution, projection) {
//   		  let url = 'http://172.168.30.2:8081/proxy.jsp?url=http://api.vworld.kr/req/wfs';
  		  let url = 'http://localhost:8081/proxy.jsp?url=http://api.vworld.kr/req/wfs';
// 		  let url = 'http://api.vworld.kr/req/wfs';
  		  let urlData = {
				  	service : 'WFS',
		        	key : key,
		        	version : '1.1.0',
					request : 'GetFeature',
					typename : 'lt_c_adsido',
					srsname : 'EPSG:3857',
		        	domain : 'localhost',
		        	//filter 적용이 된 경우에는 bbox 를 사용하지 않는다.
// 		        	bbox : extent.join(',') + ',EPSG:3857',
		        	output : 'GML3',
		        	propertyname : 'ag_geom,ctprvn_cd,ctp_kor_nm',
		        	maxfeatures : 10,
		        	filter : encodeURIComponent('<ogc:Filter>' +
			       	         '<ogc:PropertyIsEqualTo matchCase="true">' +
			           		 '<ogc:PropertyName>ctprvn_cd</ogc:PropertyName>' +
			           		 '<ogc:Literal>41</ogc:Literal>' +
		      				 '</ogc:PropertyIsEqualTo>' +
		 					 '</ogc:Filter>')
		    };
			let getUrl = url + "?" + Object.entries(urlData).map(e => e.join('=')).join('&');;
//   		  	console.log(getUrl);		  
			
  			//Object
			const xhr = new XMLHttpRequest();
		    xhr.open('GET', getUrl);
// 		    xhr.withCredentials = true;
// 		    xhr.setRequestHeader('Access-Control-Allow-Credentials', 'true');
// 		    xhr.setRequestHeader('Access-Control-Allow-Headers', '*');
// 		    xhr.setRequestHeader('Access-Control-Allow-Origin', 'http://test.com');
// 		    xhr.setRequestHeader('Access-Control-Allow-Methods', 'GET,POST,HEAD,OPTIONS');
		    
		    xhr.onload = function() {
				let formatGML = new ol.format.GML3();
				let features = formatGML.readFeatures(xhr.responseText);
				vectorSource.addFeatures(features);	
				
				console.log(features.length);
				console.log('xhr Loding Complete');
		    }
		    xhr.onerror = function(ex) {
		    	console.log(ex, xhr)
		    }
		    xhr.send();
		    
		    //XML
			$.ajax({
				type: 'post',
				dataType: 'xml',
				url: url,
				async: false,
				data: urlData,
// 				crossOrigin : true,
// 				header:{
// 					"Access-Control-Allow-Origin":"http://test.com"
// 				}
			}).done((response) => {
				let formatGML = new ol.format.GML3(); 
				let features = formatGML.readFeatures(response);
				vectorSource.addFeatures(features);
				
				console.log(features.length);
				console.log('Ajax XML Loding Complete');
			}).fail(function(ex) {
				console.log('Ajax XML Fail');
			});
			
			let jsonData = {
				  	service : 'WFS',
		        	key : key,
		        	version : '1.1.0',
					request : 'GetFeature',
					typename : 'lt_c_adsido',
					srsname : 'EPSG:3857',
		        	domain : 'localhost',
		        	bbox : extent.join(',') + ',EPSG:3857',
		        	output : 'application/json',
		        	propertyname : 'ag_geom,ctprvn_cd,ctp_kor_nm',
		        	maxfeatures : 20
		    };
			
			//Json
			$.ajax({
				type: 'get',
				url: url,
				async: false,
				data: jsonData,
				//type이 get으로 전송되는 경우에는 dataType은 의미가 없다.
				//post의 경우 xml이외 값으로 전송하게되면 오류가 발생되므로 text 를 사용하여야 한다.
				//post에 text를 사용하는 경우에는 output은 무조건 xml 로 리턴된다.
// 				dataType: 'json',
// 				crossOrigin : true,
// 				header:{
// 					"Access-Control-Allow-Origin":"http://test.com"
// 				}
				success: (response) => {
					let formatGeoJson = new ol.format.GeoJSON(); 
					let features = formatGeoJson.readFeatures(response);
					vectorSource.addFeatures(features);
					
					console.log(features.length);
					console.log('Ajax Json Loding Complete');
				},
				error: (xhr, status, error) => {
					console.log('Ajax Json Fail');
				}
			});
  	  },
  	  strategy : ol.loadingstrategy.bbox
    });
	
	let styleFunction = (feature) => {

	    return [
	        new ol.style.Style({
	            fill: new ol.style.Fill({
	            color: 'rgba(255,0,255,0.4)'
	            }),
	            stroke: new ol.style.Stroke({
	            color: '#3399CC',
	            width: 1.25
	            }),
	            text: new ol.style.Text({
	                offsetX:0.5, //위치설정
	                offsetY:20,   //위치설정
	                font: '20px Calibri,sans-serif',
	                fill: new ol.style.Fill({ color: '#000' }),
	                stroke: new ol.style.Stroke({
	                    color: '#fff', width: 3
	                }),
	                text: feature.get('ctp_kor_nm')
	            }),
	            image: new ol.style.Icon(/** @type {olx.style.IconOptions} */ ({
	                anchor: [0.5, 10],
	                anchorXUnits: 'fraction',
	                anchorYUnits: 'pixels',
	                src: 'https://map.vworld.kr/images/ol3/marker_blue.png'
	            }))
	        })
	    ];
	}
	
	map = new ol.Map({
	  target : 'map',
	  layers : [new ol.layer.Vector({
	     source : vectorSource
	  	,opacity: 1 //투명도
// 	  	,crossOrigin: 'anonymous'
	  	,style: styleFunction
// 	  	,style: new ol.style.Style({
// 	  	    stroke: new ol.style.Stroke({
// 	  	        color: 'rgba(0, 0, 255, 1.0)',
// 	  	        width: 2
// 	 	    	})
// 	 	    })
	  })],
	  view : new ol.View({
	    center : ol.proj.transform([ 127, 37.5 ], 'EPSG:4326', 'EPSG:3857')
	    ,zoom : 9
	    ,enableRotation : true
	    ,constrainResolution: true //신규추가됨 whell zoom 과 control zoom 동기화
	  })
	});
	
	map.addControl(new ol.control.FullScreen());
	
	//shift(ZoomIn), shift+alt(rotation)
	map.addControl(new ol.interaction.DragRotateAndZoom());
}


</script>    
    
</head>
<body>
<div id="map" class="map"></div>    
</body>
</html>