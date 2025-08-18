const dgram = require('dgram');
const os = require('os');

const SSDP_ADDRESS = '239.255.255.250';
const SSDP_PORT = 1900;
const SERVER_PORT = 3000;
const UDN = 'uuid:12345678-1234-1234-1234-1234567890ab';

function getIPAddress() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && iface.internal === false) {
        return iface.address;
      }
    }
  }
}

const serverIp = getIPAddress();

if (!serverIp) {
  console.error('Could not determine IP address. SSDP server not starting.');
  process.exit(1);
}
console.log('Server IP:', serverIp);

const message = Buffer.from(
  `NOTIFY * HTTP/1.1\r\n` +
  `HOST: ${SSDP_ADDRESS}:${SSDP_PORT}\r\n` +
  `CACHE-CONTROL: max-age=1800\r\n` +
  `LOCATION: http://${serverIp}:${SERVER_PORT}/dd.xml\r\n` +
  `NT: urn:schemas-upnp-org:device:MediaServer:1\r\n` +
  `NTS: ssdp:alive\r\n` +
  `SERVER: Node.js/18.0 UPnP/1.1 MedicineDisplayPOC/1.0\r\n` +
  `USN: ${UDN}::urn:schemas-upnp-org:device:MediaServer:1\r\n` +
  `\r\n`
);

// ---- Broadcaster ----
const client = dgram.createSocket({ type: 'udp4', reuseAddr: true });

client.on('listening', () => {
  console.log('UDP client ready to broadcast SSDP NOTIFY');
  client.setBroadcast(true);
  client.setMulticastTTL(128);
  client.addMembership(SSDP_ADDRESS);
});

// use ephemeral port instead of 1900
client.bind(() => {
  setInterval(() => {
    console.log('Sending SSDP NOTIFY');
    client.send(message, 0, message.length, SSDP_PORT, SSDP_ADDRESS, (err) => {
      if (err) {
        console.error('Error sending SSDP NOTIFY:', err);
      }
    });
  }, 5000);
});

// ---- Listener ----
const listener = dgram.createSocket({ type: 'udp4', reuseAddr: true });

listener.on('message', (msg, rinfo) => {
  console.log(`Got SSDP message from ${rinfo.address}:${rinfo.port}\n${msg.toString()}`);
});

listener.bind(SSDP_PORT, () => {
  listener.addMembership(SSDP_ADDRESS);
  console.log('Listening for SSDP messages on 239.255.255.250:1900');
});
