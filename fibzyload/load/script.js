var nTotal = 0;
var szProgress = "0%";
var downloadCache = [];

function SetStatusChanged( status )
{
	$('.status').html( "Connection status: " + status );
}

function DownloadingFile( fileName )
{
	downloadCache.push(fileName);
	
	var downloadText = "";
	var downloadLength = downloadCache.length;
	var downloadMin = downloadLength - 5;
	if (downloadMin < 0)
		downloadMin = 0;
	
	var opacity = 1;
	for (var i = downloadLength - 1; i >= downloadMin; i--)
	{
		downloadText = downloadText + "<span style=\"opacity: " + opacity + "\">> " + downloadCache[ i ] + "</span><br />";
		opacity -= 0.15;
	}
	
	$('.downloading').html( "Downloading (" + szProgress + "):<br /><br />" + downloadText );
}

function SetFilesTotal( total )
{
	nTotal = total;
}

function SetFilesNeeded( needed )
{
	if (nTotal == 0) { return; }
	percent = needed / nTotal;
	percent = 1 - percent;
	percent = percent * 100;
	
	szProgress = Math.round( percent )  + "%";
}

function loadPageDetails(client, server)
{
	$.ajax({
		type: "POST", url: "backend.php", data: "action=obtainPlayerDetails&client=" + client,
		complete: function(data){
			var ar = data.responseText.split(/;(.+)?/)
			$('.js_steam').html( ar[ 0 ] );
			$('.js_user').html( ar[ 1 ] );
		}
	});
	
	$.ajax({
		type: "POST", url: "backend.php", data: "action=obtainServerDetails&server=" + server,
		complete: function(data){
			var ar = data.responseText.split(/;(.+)?/)
			$('.js_map').html( ar[ 0 ] );
			$('.js_players').html( ar[ 1 ] );
		}
	});
}

$(document).ready(function(){
	var clientUser = document.getElementById("data_player").className;
	var serverPath = document.getElementById("data_server").className;
	loadPageDetails(clientUser, serverPath);
});

var totalfilez
//Gets initial total files needed.
function SetFilesTotal(total) {
    totalfilez = total;
    window.totalfiles = total;
}
//Update Progress Bar
function SetFilesNeeded(needed) {
    window.filesleft = needed;
    if(needed < 1) {
        var neededz = window.totalfiles;
    } else {
        var neededz = needed;
    }
    var percent = Math.ceil((((window.totalfiles-neededz)/2)/(window.totalfiles/2))*100);
    if(!isNan(percent)) {
        $('#progressbar').css({ "width" : percent+"%"});
        $('#progressbar').empty().append(percent+"%");
    }
}
//Update loading header text.
function SetStatusChanged( status ) {
    /*
    Retrieving server info...
    Getting addon info for #------
    Found '--'
    Mounting Addons
    Workshop Complete
    Sending client info...
    */
    if(status == 'Retrieving server info...') {
        $('#progressbar').css({ "width" : "10%"});
        $('#subtext1').empty().append("Initializing...");
    }
    if(status == 'Mounting Addons') {
        $('#progressbar').css({ "width" : "50%"});
        $('#subtext1').empty().append("Mounting Addons");
    }
    if(status == 'Workshop Complete') {
        $('#progressbar').css({ "width" : "80%"});
        $('#subtext1').empty().append("Workshop Complete");
    }
    if(status == 'Sending client info...') {
        $('#progressbar').css({"width" : "100%"}, 15000);
        $('#subtext1').empty().append('Finalizing...');
    }
}
//Downloading file event.
function DownloadingFile(fileName) {
    $('#subtext1').empty().append('Obtaining '+fileName+'.</br><b>'+window.filesleft+'</b> out of <b>'+window.totalfiles+'</b>');
}