using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace Alarm.Api.Models.Alarm;

internal class AlarmOnUpdate
{
    [JsonRequired]
    [JsonPropertyName("id")]
    public Guid Id { get; set; }

    [JsonPropertyName("mindr_userid")]
    public string? MindrUserId { get; set; } = null;

    [JsonPropertyName("mindr_connectionid")]
    public string? MindrConnectionId { get; set; } = null;

    [JsonPropertyName("time")]
    public DateTime? Time { get; set; } = null;

    [JsonPropertyName("scheduled_days")]
    public IEnumerable<int>? ScheduledDays { get; set; } = null;

    [JsonPropertyName("label")]
    public string? Label { get; set; } = null;

    [JsonPropertyName("sound")]
    public string? Sound { get; set; } = null;

    [JsonPropertyName("isEnabled")]
    public bool? IsEnabled { get; set; } = null;

    [JsonPropertyName("useVibration")]
    public bool? UseVibration { get; set; } = null;
}
