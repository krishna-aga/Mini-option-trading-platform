mockusdt=0xde725cCfD178c85ab06AeB996A93C389f5ff821b
option=0x40D6d0604446D7C2A308d8C971b18f689e012e49


Step 1- forge script script/DeployOption.s.sol --rpc-url $RPC --private-key KEY --broadcast
step 2- cast send 0xde725cCfD178c85ab06AeB996A93C389f5ff821b "mint(address,uint256)" 0x1c9a4d9712025bc208829d271e4d992115e2769a 1000000000000000000000 --private-key $KEY --rpc-url $RPC
