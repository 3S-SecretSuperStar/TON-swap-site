import "@stdlib/deploy";
import "@stdlib/ownable";
import "./tokenSwapWallet.tact";
trait Jetton with Ownable {
    totalSupply: Int; // Already set initially
    mintable: Bool;
    owner: Address;
    content: Cell;
    max_supply: Int; // This is not in the TEP-74 interface

    receive(msg: TokenUpdateContent){
        self.requireOwner(); // Allow changing content only by owner
        self.content = msg.content; // Update content
    }

    receive(msg: TokenBurnNotification){
        self.requireWallet(msg.owner); // Check wallet
        self.totalSupply = (self.totalSupply - msg.amount); // Update supply

        if (msg.response_destination != null) {
            // Cashback
            send(SendParameters{
                    to: msg.response_destination!!,
                    value: 0,
                    bounce: false,
                    mode: (SendRemainingValue + SendIgnoreErrors),
                    body: TokenExcesses{queryId: msg.queryId}.toCell()
                }
            );
        }
    }

    // @to The Address receive the Jetton token after minting
    // @amount The amount of Jetton token being minted
    // @response_destination The previous owner address
     fun mint(to: Address, amount: Int, response_destination: Address) {
        require((self.totalSupply + amount) <= self.max_supply, "The total supply will be overlapping.");
        self.totalSupply = (self.totalSupply + amount); // Update total supply

        let winit: StateInit = self.getJettonWalletInit(to); // Create message
        send(SendParameters{
                to: contractAddress(winit),
                value: 0,
                bounce: false,
                mode: SendRemainingValue,
                body: TokenTransferInternal{
                    queryId: 0,
                    amount: amount,
                    from: myAddress(),
                    response_destination: response_destination,
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
struct JettonWalletData {
    balance: Int;
    owner: Address;
    master: Address;
    walletCode: Cell;
}
message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}
message(0x178d4519) TokenTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}
message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}
message(0x595f07bc) TokenBurn {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    response_destination: Address;
}
message(0x7bdd97de) TokenBurnNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    response_destination: Address?;
}
message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;
}
message TokenUpdateContent {
    content: Cell;
}