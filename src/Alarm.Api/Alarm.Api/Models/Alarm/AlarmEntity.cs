using Azure;
using Azure.Data.Tables;

namespace Alarm.Api.Models.Alarm;

public class AlarmEntity : ITableEntity
{
    public string RowKey { get; set; }

    public string PartitionKey { get; set; }

    public DateTimeOffset? Timestamp { get; set; }

    public ETag ETag { get; set; }

    public AlarmEntity()
    {
        Id = Guid.NewGuid();
    }

    public AlarmEntity(Guid id, string userId, DateTime time)
    {
        Id = id;
        MindrUserId = userId;
        Time = time;
    }

    /// <summary>
    /// Defined as the RowKey and PartitionKey as needed by Azure Table Storage
    /// </summary>
    public Guid Id
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

    public string MindrUserId { get; set; }

    public string? MindrConnectionId { get; set; } = null;

    public DateTime Time{ get; set; }

    /// <summary>
    /// this is an array of integers representing the days of the week that the alarm is scheduled for
    /// </summary>
    public string ScheduledDays { get; set; } = "";

    public string? Label { get; set; } = null;

    public string? Sound { get; set; } = null;

    public bool IsEnabled { get; set; } = true;

    public bool UseVibration { get; set; } = true;

}
