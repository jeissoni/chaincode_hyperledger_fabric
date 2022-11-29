Implementación de un contrato inteligente en un canal


1. Iniciar la red

Entrar a la carpeta "test-network" y lanzar el siguiente comando

* para iniciar la red:
   cd test-network/ ;  ./network.sh up createChannel; cd ..

*para detener la red:
    cd test-network/ ;  ./network.sh down; cd ..

resultado:

...
Anchor peer set for org 'Org2MSP' on channel 'mychannel'
Channel 'mychannel' joined


2. Empaquetar el contrato
Puede usar la peerCLI para crear un paquete de código de cadena en el formato requerido.
Los peerbinarios se encuentran en la bincarpeta del fabric-samplesrepositorio.
Use el siguiente comando para agregar esos archivos binarios a su ruta CLI:

    export PATH=${PWD}/bin:$PATH


También debe configurar FABRIC_CFG_PATH para que apunte al core.yaml
archivo en el fabric-samplesrepositorio:

    export FABRIC_CFG_PATH=$PWD/config/

    peer version

    peer lifecycle chaincode package basic.tar.gz --path assets-chaincode/chainCode/ --lang golang --label basic_1.0


3. Instalar el paquete en la cadena
se debe instalar en los todos los pares que respladaran la transaccion

3.1 instalar en el peer 1
Configure las siguientes variables de entorno para operar la peerCLI como el usuario
administrador de Org1. se establecerá para apuntar al CORE_PEER_ADDRESS par Org1,
peer0.org1.example.com

    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=${PWD}/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051

Emita el comando de instalación del código de cadena del ciclo de vida del par para
instalar el código de cadena en el par:

    peer lifecycle chaincode install basic.tar.gz

Resultado:

    submitInstallProposal -> Chaincode code package identifier: basic_1.0: hash

Ahora podemos instalar el código de cadena en el par Org2. Establezca las siguientes variables de<
entorno para operar como administrador de Org2 y apunte al par de Org2, peer0.org2.example.com.

    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=${PWD}/test-network/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
    export CORE_PEER_ADDRESS=localhost:9051

    peer lifecycle chaincode install basic.tar.gz

Resultado:

     submitInstallProposal -> Chaincode code package identifier: basic_1.0:hash


4. Aprobar una definición de código de cadena


Si una organización ha instalado el código de cadena en su par, debe incluir el ID del paquete
en la definición de código de cadena aprobada por su organización. El ID del paquete se usa para
asociar el código de cadena instalado en un par con una definición de código de cadena aprobada
y permite que una organización use el código de cadena para respaldar transacciones.

    peer lifecycle chaincode queryinstalled

Resultado:

    Installed chaincodes on peer:
    Package ID: basic_1.0:hash..., Label: basic_1.0

Luego se debe almacenar este ID en una variable de entorno

    export CC_PACKAGE_ID=basic_1.0:hash...

Debido a que las variables de entorno se han configurado para operar la peerCLI como el administrador de Org2,
podemos aprobar la definición de código de cadena de transferencia de activos (básica) como Org2.
Chaincode está aprobado a nivel de organización, por lo que el comando solo necesita apuntar a un par.

     peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name basic --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile "${PWD}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

Resultado:

   ...  [chaincodeCmd] ClientWait -> txid [hahs] committed with status (VALID) at localhost:9051

Todavía tenemos que aprobar la definición de código de cadena como Org1.
Establezca las siguientes variables de entorno para operar como administrador de Org1:

    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_MSPCONFIGPATH=${PWD}/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
    export CORE_PEER_ADDRESS=localhost:7051


Ahora puede aprobar la definición de código de cadena como Org1.

    peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name basic --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile "${PWD}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

5. Enviar la definición de código de cadena al canal

Después de que un número suficiente de organizaciones haya aprobado una definición de código de cadena,
una organización puede enviar la definición de código de cadena al canal. Si la mayoría de los miembros
del canal han aprobado la definición, la transacción de compromiso será exitosa y los parámetros acordados
en la definición del código de cadena se implementarán en el canal.

Puede usar el comando checkcommitreadiness del código de cadena del ciclo de vida del par para comprobar si
los miembros del canal han aprobado la misma definición de código de cadena.

    peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name basic --version 1.0 --sequence 1 --tls --cafile "${PWD}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" --output json

Resultado:

    {
            "approvals": {
                    "Org1MSP": true,
                    "Org2MSP": true
            }
    }

Dado que ambas organizaciones que son miembros del canal han aprobado los mismos parámetros, la definición
del código de cadena está lista para confirmarse en el canal.

    peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name basic --version 1.0 --sequence 1 --tls --cafile "${PWD}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"

Resultado:

    2022-11-27 14:27:44.912 -05 0001 INFO [chaincodeCmd] ClientWait -> txid [hash] committed with status (VALID) at localhost:7051
    2022-11-27 14:27:44.919 -05 0002 INFO [chaincodeCmd] ClientWait -> txid [hash] committed with status (VALID) at localhost:9051


Puede usar el comando querycommitted del código de cadena del ciclo de vida del par para confirmar que la
definición del código de cadena se ha confirmado en el canal.

    peer lifecycle chaincode querycommitted --channelID mychannel --name basic --cafile "${PWD}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

Resultado:

    Committed chaincode definition for chaincode 'basic' on channel 'mychannel':
    Version: 1.0, Sequence: 1, Endorsement Plugin: escc, Validation Plugin: vscc, Approvals: [Org1MSP: true, Org2MSP: true]

6. Invocando el código de cadena

Utilice el siguiente comando para crear un conjunto inicial de activos en el libro mayor. Tenga en cuenta que el
comando de invocación debe apuntar a una cantidad suficiente de pares para cumplir con la política de respaldo de chaincode.
(Tenga en cuenta que la CLI no accede al par de Fabric Gateway, por lo que se debe especificar cada par de aprobación).

    peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c '{"function":"InitLedger","Args":[]}'

resultado:

    ... INFO [chaincodeCmd] chaincodeInvokeOrQuery -> Chaincode invoke successful. result: status:200

*   consulta para leer TODO el conjunto de datos que fueron creados por el código de cadena:

    peer chaincode query -C mychannel -n basic -c '{"Args":["GetAllAssets"]}'

resultado:
    [
    {"AppraisedValue":300,"Color":"blue","ID":"asset1","Owner":"Tomoko","Size":5},
    {"AppraisedValue":400,"Color":"red","ID":"asset2","Owner":"Brad","Size":5},
    {"AppraisedValue":500,"Color":"green","ID":"asset3","Owner":"Jin Soo","Size":10},
    {"AppraisedValue":600,"Color":"yellow","ID":"asset4","Owner":"Max","Size":10},
    {"AppraisedValue":700,"Color":"black","ID":"asset5","Owner":"Adriana","Size":15},
    {"AppraisedValue":800,"Color":"white","ID":"asset6","Owner":"Michel","Size":15}
    ]

*   consulta para leer un activo en especifico:

    peer chaincode query -C mychannel -n basic -c '{"Args":["ReadAsset", "asset1"]}

*   coonsulta para crear un activo

    peer chaincode invoke -C mychannel -n basic -c '{"Args":["CreateAsset","asset7","black","5","Tom","900"]}'


Resultado:
    {"AppraisedValue":300,"Color":"blue","ID":"asset1","Owner":"Tomoko","Size":5}


Para mas detalle consultar:
https://hyperldger-fabric.readthedocs.io/en/release-2.5/deploy_chaincode.html