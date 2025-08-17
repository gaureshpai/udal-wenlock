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
      if ('IPv4' !== iface.family || iface.internal !== false) {
        continue;
      }
      return iface.address;
    }
  }
}

const serverIp = getIPAddress();

if (!serverIp) {
  console.error('Could not determine IP address. SSDP server not starting.');
  process.exit(1);
}

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

const client = dgram.createSocket('udp4');

client.on('listening', () => {
  console.log('UDP client listening for messages');
  client.setBroadcast(true);
  client.setMulticastTTL(128);
  client.addMembership(SSDP_ADDRESS);
});

setInterval(() => {
  console.log('Sending SSDP NOTIFY');
  client.send(message, 0, message.length, SSDP_PORT, SSDP_ADDRESS, (err) => {
    if (err) {
      console.error('Error sending SSDP NOTIFY:', err);
    }
  });
}, 5000);

client.bind(SSDP_PORT);
