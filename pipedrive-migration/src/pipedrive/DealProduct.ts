export interface DealProduct {
    readonly id: number;
    readonly dealId: number;
    readonly quantity: number;
    readonly totalPrice: number;
    readonly unitPrice: number;
    readonly productId: number;
}

export function fromPipedriveDealProduct(dealProduct: any): DealProduct {
    interface PdDealProduct {
        readonly id: number;
        readonly deal_id: number;
        readonly quantity: number;
        readonly sum: number;
        readonly item_price: number;
        readonly product_id: number;
    }

    const pdDeal = dealProduct as PdDealProduct;
    return {
        id: pdDeal.id,
        dealId: pdDeal.deal_id,
        quantity: pdDeal.quantity,
        totalPrice: pdDeal.sum,
        unitPrice: pdDeal.item_price,
        productId: pdDeal.product_id,
    };
}