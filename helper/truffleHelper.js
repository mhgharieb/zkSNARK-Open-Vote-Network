async  function mineToBlockNumber(number) {
  current = await web3.eth.getBlockNumber()
  while ( current <number) 
  {
      await web3.currentProvider.send({
          jsonrpc: "2.0",
          method: "evm_mine",
          id: "*"
         }, function(err, result) {
         });
      current++
  }    
  }
  takeSnapshot = () => {
    return new Promise((resolve, reject) => {
      web3.currentProvider.send({
        jsonrpc: '2.0',
        method: 'evm_snapshot',
        id: new Date().getTime()
      }, (err, snapshotId) => {
        if (err) { return reject(err) }
        return resolve(snapshotId)
      })
    })
  }

revertToSnapshot = (id) => {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send({
      jsonrpc: '2.0',
      method: 'evm_revert',
      params: [id],
      id: new Date().getTime()
    }, (err, result) => {
      if (err) { return reject(err) }
      return resolve(result)
    })
  })
}
module.exports = {
  mineToBlockNumber,
  takeSnapshot,
  revertToSnapshot
}