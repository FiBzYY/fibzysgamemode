<?php
// Check if the required GET parameters are set
$requestuser = isset($_GET["s"]) ? htmlspecialchars($_GET["s"]) : "Unknown";
$requesttype = isset($_GET["t"]) ? htmlspecialchars($_GET["t"]) : "Unknown";
$mapname = isset($_GET["m"]) ? htmlspecialchars($_GET["m"]) : "Unknown";

// Your servers' data
$_SERVERS = array(
    "ThisServerIdentifier" => array('Bunny Hop', '1.1.1', 25000),
    "AnotherServer" => array('Bunny Hop', 'IP ADDRESS', 27015),
);

// If the request type is valid, get game data; otherwise, set it to unknown
$gamedata = isset($_SERVERS[$requesttype]) ? $_SERVERS[$requesttype] : array("Unknown", "Unknown", "Unknown");

// Your Steam API Key
$apikey = "";

// Fetch player details from Steam API if a valid SteamID is provided
if ($requestuser !== "Unknown") {
    $steamapi = file_get_contents('http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=' . $apikey . '&steamids=' . $requestuser);
    $data = json_decode($steamapi, true);
    $username = isset($data["response"]["players"][0]["personaname"]) ? htmlspecialchars($data["response"]["players"][0]["personaname"]) : "Unknown Player";
}

// Function to convert SteamID64 to SteamID
function convertSteamID($steamid64) {
    $baseid = '76561197960265728'; // This is the base ID used by Steam for SteamID64 conversion
    $difference = bcsub($steamid64, $baseid); // Subtract the base ID from the SteamID64
    $authserver = bcmod($difference, '2'); // Get the last bit to determine the Auth Server (0 or 1)
    $authid = bcdiv(bcsub($difference, $authserver), '2'); // Divide by 2 to get the account number
    return "STEAM_0:$authserver:$authid";
}

$steamid = ($requestuser !== "Unknown") ? convertSteamID($requestuser) : "Unknown";
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bunny Hop Loading Screen</title>
    <style>
        body, html {
            margin: 0;
            padding: 0;
            height: 100%;
            font-family: Arial, sans-serif;
            color: #ccc;
            overflow: hidden;
        }
        .background {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-size: cover;
            background-position: center;
            transition: opacity 1s ease-in-out;
            z-index: -1;
            opacity: 1;
            filter: blur(4px);
        }
        .background.hidden {
            opacity: 0;
        }
        .container {
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100%;
            position: relative;
        }
        .box {
            width: 600px;
            background: #222;
            padding: 0;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.5);
        }
        .content {
            text-align: center;
            padding: 20px;
            background: #222222;
        }
        .content h1 {
            margin: 0;
            font-size: 2.5em;
            color: #eee;
        }
        .content p {
            margin: 10px 0;
            font-size: 1.2em;
            color: #bbb;
        }
        .details {
            display: flex;
            width: 100%;
            color: #ccc;
        }
        .details .labels {
            background-color: #282828;
            padding: 20px;
            width: 30%;
            box-sizing: border-box;
        }
        .details .values {
            background-color: #2b2b2b;
            padding: 20px;
            width: 70%;
            box-sizing: border-box;
        }
        .details .labels div,
        .details .values div {
            padding: 10px 0;
            border-bottom: 1px solid #666;
        }
        .details .labels div:last-child,
        .details .values div:last-child {
            border-bottom: none;
        }
        #status-container {
            position: absolute;
            bottom: 20px;
            width: 100%;
            text-align: center;
            color: #fff;
        }
        #status {
            margin-bottom: 10px;
        }
        #loading {
            width: 50%;
            margin: 0 auto;
            height: 20px;
            background: #444;
            overflow: hidden;
        }
        #loading-progress {
            height: 100%;
            width: 0;
            background: #76c7c0;
        }
        #music-container {
            display: none;
        }

        /* Style for the dummy placeholder box */
        #gmodconnect-placeholder {
            position: absolute;
            bottom: 10px;
            right: 10px;
            width: 400px;
            height: 66px;
            border: 1px solid #232323;
            background-color: #000000;
            color: #BFBFBF;
            box-sizing: border-box;
            font-family: tahoma;
            font-size: 12px;
            font-weight: bold;
            padding: 6px;
            z-index: 9999;
        }
    </style>
</head>
<body>
    <div id="bg1" class="background" style="background-image: url('backgrounds/images/bg.png');"></div>
    <div id="bg2" class="background hidden" style="background-image: url('backgrounds/images/bg2.png');"></div>

    <div class="container">
        <div class="box">
            <div class="content">
                <h1 id="title">Bunny Hop</h1>
                <p>fibzy's dev server</p>
            </div>
            <div class="details">
                <div class="labels">
                    <!-- Static text labels -->
                    <div>Map</div>
                    <div>Gamemode</div>
                    <div>SteamID</div>
                    <div>Player Name</div>
                    <div>Server IP</div>
                </div>
                <div class="values">
                    <!-- Dynamic values -->
                    <div><span class="js_map"><?php echo $mapname; ?></span></div>
                    <div><span class="js_gamemode"><?php echo $gamedata[0]; ?></span></div>
                    <div><span class="js_steam"><?php echo $steamid; ?></span></div>
                    <div><span class="js_user"><?php echo $username; ?></span></div>
                    <div><span class="js_server_ip"><?php echo htmlspecialchars($gamedata[1] . ':' . $gamedata[2]); ?></span></div>
                </div>
            </div>
        </div>
    </div>

    <div id="status-container">
        <div id="status">Retrieving server info...</div>
        <div id="loading">
            <div id="loading-progress"></div>
        </div>
    </div>

    <!-- Dummy box to cover the default GMod loading bar -->
    <div id="gmodconnect-placeholder">Loading...</div>

    <div id="music-container">
        <div id="player"></div>
    </div>

 <script>
    // Fisher-Yates shuffle algorithm
    function shuffle(array) {
        var currentIndex = array.length, temporaryValue, randomIndex;

        while (0 !== currentIndex) {
            randomIndex = Math.floor(Math.random() * currentIndex);
            currentIndex -= 1;

            temporaryValue = array[currentIndex];
            array[currentIndex] = array[randomIndex];
            array[randomIndex] = temporaryValue;
        }

        return array;
    }

    var neededFiles = 0;
    var downloadedFiles = 0;

    function GameDetails(servername, serverurl, mapname, maxplayers, steamid, gamemode) {
        setGamemode(gamemode);
        setMapname(mapname);

        if (!l_serverName && !l_serverImage) {
            setServerName(servername);
        }
    }

    function DownloadingFile(fileName) {
        downloadedFiles++;
        refreshProgress();
        setStatus("Downloading files...");
    }

    function SetStatusChanged(status) {
        if (status.indexOf("Getting Addon #") != -1) {
            downloadedFiles++;
            refreshProgress();
        } else if (status == "Sending client info...") {
            setProgress(100);
        }

        setStatus(status);
    }

    function SetFilesNeeded(needed) {
        neededFiles = needed + 1;
    }

    function refreshProgress() {
        var progress = Math.floor(((downloadedFiles / neededFiles) * 100));
        setProgress(progress);
    }

    function setStatus(text) {
        document.getElementById("status").innerText = text;
    }

    function setProgress(progress) {
        document.getElementById("loading-progress").style.width = progress + "%";
    }

    function setGamemode(gamemode) {
        document.getElementById("gamemode").innerText = gamemode;
    }

    function setMapname(mapname) {
        document.getElementById("map").innerText = mapname;
    }

    function setServerName(servername) {
        document.getElementById("title").innerText = servername;
    }

    // Function to generate a random RGB color
    function getRandomRGB() {
        var r = Math.floor(Math.random() * 256);
        var g = Math.floor(Math.random() * 256);
        var b = Math.floor(Math.random() * 256);
        return 'rgb(' + r + ',' + g + ',' + b + ')';
    }

    document.addEventListener('DOMContentLoaded', function() {
        // Array of background images
        const images = [
            'backgrounds/images/bg.png',
            'backgrounds/images/bg2.png',
            'backgrounds/images/bg3.png',
            'backgrounds/images/bg4.png',
            'backgrounds/images/bg5.png',
            'backgrounds/images/bg6.jpg',
            'backgrounds/images/bg7.jpg',
            'backgrounds/images/bg8.jpg',
        ];

        // Shuffle images to randomize the order
        shuffle(images);

        // Select a random index to start with
        let currentIndex = Math.floor(Math.random() * images.length);
        const bg1 = document.getElementById('bg1');
        const bg2 = document.getElementById('bg2');

        // Initially set the first background to a random image
        bg1.style.backgroundImage = `url(${images[currentIndex]})`;

        // Function to rotate the background images
        function changeBackground() {
            currentIndex = (currentIndex + 1) % images.length;
            if (bg1.classList.contains('hidden')) {
                bg1.style.backgroundImage = `url(${images[currentIndex]})`;
                bg1.classList.remove('hidden');
                bg2.classList.add('hidden');
            } else {
                bg2.style.backgroundImage = `url(${images[currentIndex]})`;
                bg2.classList.remove('hidden');
                bg1.classList.add('hidden');
            }
        }

        // Change background every 10 seconds
        setInterval(changeBackground, 10000);

        // Initialize progress bar
        SetFilesNeeded(100);

        // Load YouTube API for music
        var tag = document.createElement('script');
        tag.src = "https://www.youtube.com/iframe_api";
        var firstScriptTag = document.getElementsByTagName('script')[0];
        firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

        // Set a random color for the loading bar each time the page loads
        const progressBar = document.getElementById('loading-progress');
        progressBar.style.backgroundColor = getRandomRGB();
    });
</script>

</body>
</html>
