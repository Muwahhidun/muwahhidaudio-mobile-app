import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/user.dart';
import '../models/theme.dart';
import '../models/book.dart';
import '../models/book_author.dart';
import '../models/teacher.dart';
import '../models/series.dart';
import '../models/lesson.dart';
import '../models/paginated_response.dart';
import '../models/system_settings.dart';
import '../models/feedback.dart';

part 'api_client.g.dart';

@RestApi(baseUrl: '')
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  // Auth endpoints
  @POST('/auth/login')
  Future<AuthResponse> login(@Body() LoginRequest request);

  @POST('/auth/register')
  Future<AuthResponse> register(@Body() RegisterRequest request);

  @GET('/auth/me')
  Future<User> getCurrentUser();

  @PUT('/auth/me')
  Future<User> updateProfile(@Body() UserProfileUpdate profileData);

  @GET('/auth/verify-email')
  Future<EmailVerificationResponse> verifyEmail(@Query('token') String token);

  @POST('/auth/resend-verification')
  Future<ResendVerificationResponse> resendVerification(@Body() ResendVerificationRequest request);

  // Settings endpoints
  @GET('/settings/notifications')
  Future<SMTPSettings> getSMTPSettings();

  @PUT('/settings/notifications')
  Future<SMTPSettings> updateSMTPSettings(@Body() SMTPSettings settings);

  @POST('/settings/notifications/test')
  Future<TestEmailResponse> sendTestEmail(@Body() TestEmailRequest request);

  // Users management endpoints
  @GET('/users')
  Future<PaginatedResponse<User>> getUsers({
    @Query('search') String? search,
    @Query('role_id') int? roleId,
    @Query('is_active') bool? isActive,
    @Query('skip') int? skip,
    @Query('limit') int? limit,
  });

  @GET('/users/{id}')
  Future<User> getUserById(@Path('id') int id);

  @PUT('/users/{id}')
  Future<User> updateUser(
    @Path('id') int id,
    @Body() Map<String, dynamic> userData,
  );

  @DELETE('/users/{id}')
  Future<void> deleteUser(@Path('id') int id);

  // Themes endpoints
  @GET('/themes')
  Future<PaginatedResponse<AppThemeModel>> getThemes({
    @Query('search') String? search,
    @Query('include_inactive') bool? includeInactive,
    @Query('skip') int? skip,
    @Query('limit') int? limit,
  });

  @GET('/themes/{id}')
  Future<AppThemeModel> getTheme(@Path('id') int id);

  @POST('/themes')
  Future<AppThemeModel> createTheme(@Body() Map<String, dynamic> theme);

  @PUT('/themes/{id}')
  Future<AppThemeModel> updateTheme(
    @Path('id') int id,
    @Body() Map<String, dynamic> theme,
  );

  @DELETE('/themes/{id}')
  Future<void> deleteTheme(@Path('id') int id);

  // Books endpoints
  @GET('/books')
  Future<PaginatedResponse<BookModel>> getBooks({
    @Query('search') String? search,
    @Query('theme_id') int? themeId,
    @Query('author_id') int? authorId,
    @Query('include_inactive') bool? includeInactive,
    @Query('skip') int? skip,
    @Query('limit') int? limit,
  });

  @GET('/books/{id}')
  Future<BookModel> getBook(@Path('id') int id);

  @POST('/books')
  Future<BookModel> createBook(@Body() Map<String, dynamic> book);

  @PUT('/books/{id}')
  Future<BookModel> updateBook(
    @Path('id') int id,
    @Body() Map<String, dynamic> book,
  );

  @DELETE('/books/{id}')
  Future<void> deleteBook(@Path('id') int id);

  // Book Authors endpoints
  @GET('/book-authors')
  Future<PaginatedResponse<BookAuthorModel>> getBookAuthors({
    @Query('search') String? search,
    @Query('birth_year_from') int? birthYearFrom,
    @Query('birth_year_to') int? birthYearTo,
    @Query('death_year_from') int? deathYearFrom,
    @Query('death_year_to') int? deathYearTo,
    @Query('include_inactive') bool? includeInactive,
    @Query('skip') int? skip,
    @Query('limit') int? limit,
  });

  @GET('/book-authors/{id}')
  Future<BookAuthorModel> getBookAuthor(@Path('id') int id);

  @POST('/book-authors')
  Future<BookAuthorModel> createBookAuthor(@Body() Map<String, dynamic> author);

  @PUT('/book-authors/{id}')
  Future<BookAuthorModel> updateBookAuthor(
    @Path('id') int id,
    @Body() Map<String, dynamic> author,
  );

  @DELETE('/book-authors/{id}')
  Future<void> deleteBookAuthor(@Path('id') int id);

  // Teachers endpoints
  @GET('/teachers')
  Future<PaginatedResponse<TeacherModel>> getTeachers({
    @Query('search') String? search,
    @Query('include_inactive') bool? includeInactive,
    @Query('skip') int? skip,
    @Query('limit') int? limit,
  });

  @GET('/teachers/{id}')
  Future<TeacherModel> getTeacher(@Path('id') int id);

  @POST('/teachers')
  Future<TeacherModel> createTeacher(@Body() Map<String, dynamic> teacher);

  @PUT('/teachers/{id}')
  Future<TeacherModel> updateTeacher(@Path('id') int id, @Body() Map<String, dynamic> teacher);

  @DELETE('/teachers/{id}')
  Future<void> deleteTeacher(@Path('id') int id);

  @GET('/teachers/{id}/series')
  Future<List<SeriesModel>> getTeacherSeries(@Path('id') int id);

  // Series endpoints
  @GET('/series')
  Future<PaginatedResponse<SeriesModel>> getSeries({
    @Query('search') String? search,
    @Query('teacher_id') int? teacherId,
    @Query('book_id') int? bookId,
    @Query('theme_id') int? themeId,
    @Query('year') int? year,
    @Query('is_completed') bool? isCompleted,
    @Query('include_inactive') bool? includeInactive,
    @Query('skip') int? skip,
    @Query('limit') int? limit,
  });

  @GET('/series/{id}')
  Future<SeriesModel> getSeriesById(@Path('id') int id);

  @POST('/series')
  Future<SeriesModel> createSeries(@Body() Map<String, dynamic> series);

  @PUT('/series/{id}')
  Future<SeriesModel> updateSeries(@Path('id') int id, @Body() Map<String, dynamic> series);

  @DELETE('/series/{id}')
  Future<void> deleteSeries(@Path('id') int id);

  @GET('/series/{id}/lessons')
  Future<List<Lesson>> getSeriesLessons(@Path('id') int id);

  // Lessons endpoints
  @GET('/lessons')
  Future<PaginatedResponse<Lesson>> getLessons({
    @Query('search') String? search,
    @Query('series_id') int? seriesId,
    @Query('teacher_id') int? teacherId,
    @Query('book_id') int? bookId,
    @Query('theme_id') int? themeId,
    @Query('include_inactive') bool? includeInactive,
    @Query('skip') int? skip,
    @Query('limit') int? limit,
  });

  @GET('/lessons/{id}')
  Future<Lesson> getLesson(@Path('id') int id);

  @POST('/lessons')
  Future<Lesson> createLesson(@Body() Map<String, dynamic> lesson);

  @PUT('/lessons/{id}')
  Future<Lesson> updateLesson(@Path('id') int id, @Body() Map<String, dynamic> lesson);

  @DELETE('/lessons/{id}')
  Future<void> deleteLesson(@Path('id') int id);

  // Feedback endpoints
  @POST('/feedbacks')
  Future<Feedback> createFeedback(@Body() FeedbackCreate feedback);

  @GET('/feedbacks/my')
  Future<PaginatedFeedbacksResponse> getMyFeedbacks({
    @Query('skip') int? skip,
    @Query('limit') int? limit,
  });

  @GET('/feedbacks/{id}')
  Future<Feedback> getFeedback(@Path('id') int id);

  @GET('/feedbacks')
  Future<PaginatedFeedbacksResponse> getAllFeedbacks({
    @Query('status_filter') String? statusFilter,
    @Query('user_id') int? userId,
    @Query('search') String? search,
    @Query('skip') int? skip,
    @Query('limit') int? limit,
  });

  @PUT('/feedbacks/{id}')
  Future<Feedback> updateFeedback(
    @Path('id') int id,
    @Body() FeedbackAdminUpdate update,
  );

  @POST('/feedbacks/{id}/messages')
  Future<FeedbackMessage> createFeedbackMessage(
    @Path('id') int id,
    @Body() FeedbackMessageCreate message,
  );

  @DELETE('/feedbacks/{feedbackId}/messages/{messageId}')
  Future<void> deleteFeedbackMessage(
    @Path('feedbackId') int feedbackId,
    @Path('messageId') int messageId,
  );

  @DELETE('/feedbacks/{id}')
  Future<void> deleteFeedback(
    @Path('id') int id,
  );
}
