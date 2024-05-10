import "@stdlib/deploy";
import "@stdlib/ownable";
import "./tokenSwapWallet.tact";
trait LPToken with Ownable {
    tokenAddress: Address;
    num_of_token: Int;
    num_of_TON: Int;
    owner: Address;

    // @to The Address receive the Jetton token after minting
    // @amount The amount of Jetton token being minted
    // @response_destination The previous owner address
     fun mint(amount: Int, to: Address) {
        let winit: StateInit = self.getJettonWalletInit(to);
        send(SendParameters{
                to: contractAddress(winit),
                value: 0,
                bounce: false,
                mode: SendRemainingValue,
                body: TokenTransferInternal{
                    queryId: 0,
                    amount: amount,
                    from: myAddress(),
                    forward_ton_amount: 0,
                    forward_payload: emptySlice()
                }.toCell(),
                code: winit.code,
                data: winit.data
            }
        );
    }

     fun requireWallet(owner: Address) {
        let ctx: Context = context();
        let winit: StateInit = self.getJettonWalletInit(owner);
        require(contractAddress(winit) == ctx.sender, "Invalid sender");
    }

    virtual fun getJettonWalletInit(address: Address): StateInit {
        return initOf JettonDefaultWallet(myAddress(), address);
    }

    // ====== Get Methods ====== //

    get fun get_wallet_address(owner: Address): Address {
        let winit: StateInit = self.getJettonWalletInit(owner);
        return contractAddress(winit);
    }
}