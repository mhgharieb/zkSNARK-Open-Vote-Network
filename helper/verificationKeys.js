/* eslint-disable no-plusplus */
const fs = require('fs');

function formatVKey(vkey) {
  const IC = [];
  for (let i = 0; i < vkey.IC.length; i++) {
    IC.push({ X: BigInt(vkey.IC[i][0]), Y: BigInt(vkey.IC[i][1]) });
  }
  return {
    alpha1: {
      X: BigInt(vkey.vk_alpha_1[0]),
      Y: BigInt(vkey.vk_alpha_1[1]),
    },
    beta2: {
      X: [BigInt(vkey.vk_beta_2[0][1]), BigInt(vkey.vk_beta_2[0][0])],
      Y: [BigInt(vkey.vk_beta_2[1][1]), BigInt(vkey.vk_beta_2[1][0])],
    },
    gamma2: {
      X: [BigInt(vkey.vk_gamma_2[0][1]), BigInt(vkey.vk_gamma_2[0][0])],
      Y: [BigInt(vkey.vk_gamma_2[1][1]), BigInt(vkey.vk_gamma_2[1][0])],
    },
    delta2: {
      X: [BigInt(vkey.vk_delta_2[0][1]), BigInt(vkey.vk_delta_2[0][0])],
      Y: [BigInt(vkey.vk_delta_2[1][1]), BigInt(vkey.vk_delta_2[1][0])],
    },
    IC,
  };
}

function getVerificationKeys(vkJSONfile) {
  return formatVKey(JSON.parse(fs.readFileSync(vkJSONfile)));
}
module.exports = {
  getVerificationKeys,
};
