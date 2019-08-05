

#!/bin/bash

export db_address=12.34.56.78
export db_port=5555
export server_port=8883
output=$(curl "http://localhost:$server_port")
if [[ $output == *"Hello, World"* ]]; then
echo "Success! Got expected text from server."
else
echo "Error. Did not get back expected text 'Hello, World'."
fi


cat > index.html <<EOF
<h1>Hello, World</h1>
<p>DB address: ${db_address}</p>
<p>DB port: ${db_port}</p>
EOF
nohup busybox httpd -f -p "${server_port}" &
