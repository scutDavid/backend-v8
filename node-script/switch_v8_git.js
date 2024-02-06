const fs = require('fs');

let v8_py_path = process.argv[2] + '/fetch_configs/v8.py';
let v8_py_context = fs.readFileSync(v8_py_path, 'utf-8');
v8_py_context = v8_py_context.replace('https://chromium.googlesource.com/v8/v8.git','https://github.com/scutDavid/v8');
fs.writeFileSync(v8_py_path, v8_py_context);

