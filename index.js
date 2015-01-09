var app = require('express')();
var http = require('http');
var https = require('https');
var server = http.Server(app);
var io = require('socket.io')(server);
var querystring = require('querystring');

app.get('/', function(req, res){
	res.send('<h1>Hello World</h1>');
});

app.get('/demo_page', function(req, res){
	res.sendFile(__dirname + '/demo_page.html');
});

server.listen(3000, function(){
	console.log('listening on port 3000');
});

var clients = {};

function addClient(roomId, socket){
	if(!(roomId in clients)){
		clients["" + roomId] = [];
	}

	clients["" + roomId].push(socket);
}

function removeClient(socket){
	for(roomId in clients){
		var index = clients[roomId].indexOf(socket);
		if(index > -1){
			clients[roomId].splice(index, 1);
			if(clients[roomId].length <= 0){
				delete clients[roomId];
			}
		}
	}
}

function isRoomFull(roomId){
	return clients["" + roomId] && clients["" + roomId].length >= 2;
}

io.on('connection', function(socket){
	socket.on('disconnect', function(){
		removeClient(socket);
	});

	socket.on('checkClients', function(){
		for(var roomId in clients){
			var roomClients = clients[roomId];
			console.log("Room: " + roomId + " contains " + roomClients.length + " clients")
		}
	});

	socket.on('joinRoom', function(data){
		console.log("Client trying to join: " + data.roomId);
		if(data.roomId){
			if(isRoomFull(data.roomId)){
				socket.emit('roomFull', {roomId: data.roomId});
				return;
			}

			var roomId = data.roomId;

			console.log("Client joined room: " + data.roomId);

			addClient(data.roomId, socket);
			socket.emit('roomConnected', {isInitiator: clients["" + data.roomId].length == 1, numberClients: clients["" + data.roomId].length});
			
			if(clients["" + roomId].length >= 2){
				var initiator = clients["" + roomId][0];
				initiator.emit('peerConnected', {isInitiator: true});
				clients["" + roomId][1].emit('peerConnected', {isInitiator: false});
			}

			var peer = function(){
				if(clients["" + roomId].length < 2){
					return null;
				}

				return (socket == clients["" + roomId][0]) ? clients["" + roomId][1] : clients["" + roomId][0];				
			};

			socket.on('forwardRTCSDP', function(data){
				var peerSocket = peer();
				console.log("Forwarding RTCSDP to Peer: " + peerSocket + " in room: " + roomId);
				if(peerSocket && data.sdp){
					console.log("Forwarding RTCSDP in room: " + roomId);
					peerSocket.emit('RTCSessionDescription', {sdp: data.sdp});
				}
			});

			socket.on('forwardRTCICECandidate', function(data){
				var peerSocket = peer();
				if(peerSocket && data.candidate){
					peerSocket.emit('RTCICECandidate', {candidate: data.candidate});
				}
			});

			socket.on('getICEServers', function(){
				console.log("Requesting ICE Servers for peer in room: " + roomId);

					var post_data = querystring.stringify({
						ident: "sturgmeister",
						secret: "a0ee1ed2-fa0a-4f36-9f1d-fe2f8ccc788b",
						domain: "www.realbotics.com",
						application: "default",
						room: "default",
						secure: 1
					});

					var post_options = {
						host: 'api.xirsys.com',
						port: '443',
						path: '/getIceServers',
						method: 'POST',
						headers: {
							'Content-Type': 'application/x-www-form-urlencoded',
							'Content-Length': post_data.length
						}
					};

				  var post_req = https.request(post_options, function(res) {
				  	res.setEncoding('utf8');
				  	var responseString = "";
				  	res.on('data', function (chunk) {
				  		responseString += chunk;
				  	});

				  	res.on('end', function(){
				  		try{
				  			var iceServers = JSON.parse(responseString);
				  			console.log("Forwarding ICE Config to peer in room: " + roomId);
				  			socket.emit('iceServerConfig', {servers: iceServers.d});
				  		} catch(error){
				  			console.log("Failed to parse /getIceServers response");
				  			console.log(responseString);
				  			console.log(error);
				  		}
				  	});
				  });

				  post_req.on('error', function(error){
				  	console.log("Failed to request /getIceServers");
				  	console.log(error);
				  });

				  // post the data
				  post_req.write(post_data);
				  post_req.end();
			});
		}
	});
});