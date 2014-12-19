var app = require('express')();
var http = require('http').Server(app);
var io = require('socket.io')(http);
var querystring = require('querystring');

app.get('/', function(req, res){
	res.send('<h1>Hello World</h1>');
});

app.get('/demo_page', function(req, res){
	res.sendFile(__dirname + '/demo_page.html');
});

http.listen(3000, function(){
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

	socket.on('joinRoom', function(data){
		if(data.roomId){
			if(isRoomFull){
				socket.emit('roomFull', {roomId: data.roomId});
				return;
			}

			addClient(data.roomId, socket);
			socket.emit('roomConnected', {isInitiator: clients["" + data.roomId].length == 1, numberClients: clients["" + data.roomId].length});
			
			if(clients["" + roomId].length >= 2){
				var initiator = clients["" + roomId][0];
				initiator.emit('peerConnected', {isInitiator: true});
			}

			var peer = function(){
				if(clients["" + roomId].length < 2){
					return null;
				}

				return (socket == clients["" + roomId][0]) ? clients["" + roomId][1] : clients["" + roomId][0];				
			};

			socket.on('forwardRTCOffer', function(data){
				var peerSocket = peer();
				if(peerSocket && data.offer){
					peerSocket.emit('RTCSessionDescription', {sdp: data.offer});
				}
			});

			socket.on('forwardRTCAnswer', function(data){
				var peerSocket = peer();
				if(peerSocket && data.answer){
					peerSocket.emit('RTCSessionDescription', {sdp: data.answer});
				}
			});

			socket.on('forwardRTCICECandidate', function(data){
				var peerSocket = peer();
				if(peerSocket && data.candidate){
					peerSocket.emit('RTCICECandidate', {candidate: data.candidate});
				}
			});

			socket.io('getICEServers', function(){
					var post_data = querystring.stringify({
						ident: "sturgmeister",
						secret: "a0ee1ed2-fa0a-4f36-9f1d-fe2f8ccc788b",
						domain: "www.realbotics.com",
						application: "default",
						room: "default",
						secure: 1
					});

					var post_options = {
						host: 'https://api.xirsys.com',
						port: '80',
						path: '/getIceServers',
						method: 'POST',
						headers: {
							'Content-Type': 'application/x-www-form-urlencoded',
							'Content-Length': post_data.length
						}
					};

				  var post_req = http.request(post_options, function(res) {
				  	res.setEncoding('utf8');
				  	var responseString = "";
				  	res.on('data', function (chunk) {
				  		responseString += chunk;
				  	});

				  	res.on('end', function(){
				  		try{
				  			var iceServers = JSON.parse(responseString);
				  			socket.emit('iceServerConfig', {servers: iceServers});
				  		} catch(error){
				  			console.log("Failed to parse /getIceServers response");
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