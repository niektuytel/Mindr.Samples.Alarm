using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace Alarm.Api.Models.AlarmAction;

public class AlarmOnPush
{
    [JsonPropertyName("id")]
    public int? Id { get; set; }

    [JsonPropertyName("label")]
    public string Label { get; set; } = string.Empty;

    [JsonRequired]
    [JsonPropertyName("time")]
    public DateTime Time { get; set; }

    [JsonPropertyName("scheduled_days")]
    public List<int> ScheduledDays { get; set; } = new List<int>();

    [JsonPropertyName("sound")]
    public string Sound { get; set; } = "default";

    [JsonPropertyName("vibration_checked")]
    public bool VibrationChecked { get; set; } = true;
}
