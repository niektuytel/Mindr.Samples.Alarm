namespace Alarm.Api.Models.AlarmAction;

// Define the Alarm class representing the "alarm" property in the JSON.
public class AlarmDTO
{
    public int Id { get; set; }
    public string Label { get; set; }
    public DateTime Time { get; set; }
    public int[] ScheduledDays { get; set; }
    public string Sound { get; set; }
    public bool VibrationChecked { get; set; }
}
