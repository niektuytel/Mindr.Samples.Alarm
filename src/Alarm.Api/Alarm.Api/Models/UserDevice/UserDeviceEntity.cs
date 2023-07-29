using Azure;
using Azure.Data.Tables;

namespace Alarm.Api.Models.AlarmConnection;

public class UserDeviceEntity
    : ITableEntity
{
    public string RowKey { get; set; }

    public string PartitionKey { get; set; }

    public DateTimeOffset? Timestamp { get; set; }

    public ETag ETag { get; set; }

    public UserDeviceEntity()
    {
    }

    public UserDeviceEntity(Guid userId, string fcmToken)
    {
        UserId = userId;
        FCMToken = fcmToken;
    }

    /// <summary>
    /// Defined as the RowKey and PartitionKey as needed by Azure Table Storage
    /// </summary>
    public Guid UserId
    {
        get
        {
            if (Guid.TryParse(RowKey, out var id))
            {
                return id;
            }

            throw new InvalidOperationException("RowKey is not a valid Guid");
        }
        private set
        {
            RowKey = value.ToString();
            PartitionKey = value.ToString();
        }
    }

    public string FCMToken { get; set; }

}
