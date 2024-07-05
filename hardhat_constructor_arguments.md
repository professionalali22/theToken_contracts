const injectedWeb3 = require("./helper/injectedWeb3");

let web3;

// module.exports = contructorArgs = async (contract_address, amount) => {
//   web3 = await injectedWeb3.getSocket();

//   let hex = web3.eth.abi.encodeParameter(
//     {
//       ParentStruct: {
//         propertyOne: "address",
//         propertyTwo: "uint256",
//       },
//     },
//     {
//       propertyOne: contract_address,
//       propertyTwo: amount,
//     }
//   );
//   return hex;
// };

const reg = "0xA959698895B7628839515512012634054C5f5CAC";
const admin = "0x52C75ad49024dB2474cB8a581F625bee2E14e8E7";
const token = "0xAcfCCF6D631f546a15724df59e51e430B21f92bc";

const contructorArgs = async () => {
  web3 = await injectedWeb3.getSocket();

  let hex = web3.eth.abi.encodeParameter(
    {
      ParentStruct: {
        propertyOne: "address",
        propertyTwo: "address",
        propertyThree: "address",
      },
    },
    {
      propertyOne: reg,
      propertyTwo: admin,
      propertyThree: token,
    }
  );
  console.log("🚀 ~ contructorArgs ~ hex:", hex);
  return hex;
};
contructorArgs();