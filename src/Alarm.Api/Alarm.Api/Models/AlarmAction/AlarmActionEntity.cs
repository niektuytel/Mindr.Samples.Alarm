using Azure;
using Azure.Data.Tables;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace Alarm.Api.Models.AlarmAction;

public class AlarmActionEntity : ITableEntity
{
    // Properties for the main JSON fields.
    public string UserId { get; set; }
    public string ActionType { get; set; }

    public string? AlarmJson { get; set; }

    [IgnoreDataMember]
    public AlarmDTO? Alarm
    {
        get => AlarmJson == null ? null : JsonSerializer.Deserialize<AlarmDTO>(AlarmJson);
        set => AlarmJson = JsonSerializer.Serialize(value);
    }

    // Implementation of the ITableEntity interface.
    // The PartitionKey and RowKey properties are required by Azure Table Storage.
    public string PartitionKey { get; set; }
    public string RowKey { get; set; }
    public DateTimeOffset? Timestamp { get; set; }
    public ETag ETag { get; set; }
}
