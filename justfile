start profile: (server profile) client

server profile:
	cd server && aws-vault exec {{profile}} -- cargo run & 

client:
	npm start
