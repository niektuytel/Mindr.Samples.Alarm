using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace Alarm.Api.Models.Alarm;

internal class AlarmOnCreate
{
    [JsonPropertyName("mindr_userid")]
    public string? MindrUserId { get; set; } = null;

    [JsonPropertyName("mindr_connectionid")]
    public string? MindrConnectionId { get; set; } = null;

    [JsonRequired]
    [JsonPropertyName("utc_time")]
    public DateTime Time { get; set; }

    [JsonPropertyName("scheduled_days")]
    public IEnumerable<int> ScheduledDays { get; set; } = Enumerable.Empty<int>();

    [JsonPropertyName("label")]
    public string? Label { get; set; } = null;

    [JsonPropertyName("sound")]
    public string? Sound { get; set; } = null;

    [JsonPropertyName("isEnabled")]
    public bool IsEnabled { get; set; } = true;

    [JsonPropertyName("useVibration")]
    public bool UseVibration { get; set; } = true;
}
