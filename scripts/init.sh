cp packages/service1/env.example packages/service1/.env.local && cp packages/service2/env.example packages/service2/.env.local

cp packages/service1/env.example packages/service1/.env.production && cp packages/service2/env.example packages/service2/.env.production

npm i -g lerna
echo
yarn