using Alarm.Api.Models;
using Alarm.Api.Models.AlarmAction;

public interface INotificationService
{
    Task<CloudMessageResponse> SendNotificationAsync(string fcmToken, string title, string body, AlarmActionOnPush alarmAction);
}