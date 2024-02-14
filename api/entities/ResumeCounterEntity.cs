using Azure;
using Azure.Data.Tables;

namespace api.entities;

public class ResumeCounterEntity : ITableEntity
{
    public int Count { get; set; }
    public string PartitionKey { get; set; }
    public string RowKey { get; set; }
    public DateTimeOffset? Timestamp { get; set; }
    public ETag ETag { get; set; }
}