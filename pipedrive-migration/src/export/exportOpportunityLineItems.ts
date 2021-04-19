import { CsvWriter } from '../Csv';
import { IDatabase } from '../Database';

export async function exportOpportunityLineItems(database: IDatabase) {
    const csv = new CsvWriter('OpportunityLineItems.csv');

    interface DbDealProduct {
        Id: number;
        DealId: number;
        ProductId: number;
        Quantity: number;
        ItemPrice: number;
        Sum: number;
    }
    const dealProducts = await database.query<DbDealProduct>(`
        SELECT
            Id,
            DealId,
            ProductId,
            Quantity,
            ItemPrice,
            Sum
        FROM
            deal_products
        WHERE
            json_extract(Raw, '$.enabled_flag')
    `);

    csv.writeRow([
        'PricebookEntry:Pipedrive_Id__c',
        'Opportunity:Pipedrive_Id__c',
        'Quantity',
        'TotalPrice'
    ]);

    for (const dealProduct of dealProducts) {
        csv.writeRow([
            dealProduct.ProductId.toString(),
            dealProduct.DealId.toString(),
            dealProduct.Quantity.toString(),
            dealProduct.Sum.toString()
        ]);
    }

    csv.end();

    console.log('Can **upsert** OpportunityLineItem.csv after inserting opportunities');
}