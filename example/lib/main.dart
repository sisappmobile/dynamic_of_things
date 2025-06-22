import "dart:convert";
import "dart:io";

import "package:base/base.dart";
import "package:crypto/crypto.dart" as crypto;
import "package:device_info/device_info.dart";
import "package:dio/dio.dart";
import "package:dio/io.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
import "package:dynamic_of_things/helper/dot_routes.dart";
import "package:dynamic_of_things/helper/formats.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_bloc.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_bloc.dart";
import "package:dynamic_of_things/module/dynamic_form/list/dynamic_form_list_bloc.dart";
import "package:dynamic_of_things/module/dynamic_form/menu/dynamic_form_menu_bloc.dart";
import "package:dynamic_of_things/module/dynamic_report/dynamic_report_bloc.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:get/get.dart" as g;
import "package:go_router/go_router.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:loader_overlay/loader_overlay.dart";
import "package:smooth_corner/smooth_corner.dart";

const String sessionIdKey = "sessionId";
const String usernameKey = "username";
const String baseUrl = "https://192.168.90.202:8443/salesforce/api/";
const String salt = "72e4425c484016c95677d1a2513681ff8e2b2459b11e68c8b67cc7b7fe60c422b629eb45d1a5b236c3df0031860c98f4b0f58c2497212ee20d58a833b9a3ea1d";

final GoRouter goRouter = GoRouter(
  routes: [
    GoRoute(
      path: "/",
      builder: (context, state) {
        return HomePage();
      },
    ),
    GoRoute(
      path: "/sign-in",
      builder: (context, state) {
        return SignInPage();
      },
    ),
    ...dotRoutes,
  ],
  initialLocation: "/",
  redirect: (context, state) {
    if (!BasePreferences.getInstance().contain(sessionIdKey)) {
      return "/sign-in";
    }

    return null;
  },
  navigatorKey: g.Get.key,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  initializeDateFormatting();

  await EasyLocalization.ensureInitialized();

  AppColors.lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light);
  AppColors.darkColorScheme = ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark);

  DotApis.getInstance().init(
    baseUrl,
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers["sfa-session-id"] = BasePreferences.getInstance().getString(sessionIdKey);
        options.headers["sfa-timestamp"] = DateTime.now().millisecondsSinceEpoch.toString();
        options.headers["sfa-security-code"] = crypto.sha256.convert(utf8.encode('$salt${options.headers["sfa-session-id"]}${options.headers["sfa-timestamp"]}')).toString();

        return handler.next(options);
      },
    ),
  );

  await BasePreferences.getInstance().init();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale("en"), Locale("id")],
      path: "assets/i18n",
      useFallbackTranslations: true,
      fallbackLocale: const Locale("id"),
      saveLocale: true,
      startLocale: const Locale("id"),
      child: const App(),
    ),
  );
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => AppState();
}

class AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (BuildContext context) => DynamicFormMenuBloc()),
        BlocProvider(create: (BuildContext context) => DynamicFormListBloc()),
        BlocProvider(create: (BuildContext context) => DynamicFormBloc()),
        BlocProvider(create: (BuildContext context) => DynamicReportBloc()),
        BlocProvider(create: (BuildContext context) => DynamicChartBloc()),
      ],
      child: GlobalLoaderOverlay(
        child: DismissKeyboard(
          child: MaterialApp.router(
            scrollBehavior: BaseScrollBehavior(),
            title: "Vireo Order Fulfillment Display",
            routerConfig: goRouter,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: "Manrope",
              colorScheme: AppColors.lightColorScheme,
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.size10),
                    smoothness: 1,
                  ),
                  padding: EdgeInsets.all(Dimensions.size20),
                  textStyle: TextStyle(
                    fontSize: Dimensions.text12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.size10),
                    smoothness: 1,
                  ),
                  padding: EdgeInsets.all(Dimensions.size20),
                  textStyle: TextStyle(
                    fontSize: Dimensions.text12,
                    fontWeight: FontWeight.w500,
                  ),
                  foregroundColor: AppColors.onSurface(),
                  iconColor: AppColors.onSurface(),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.size10),
                    smoothness: 1,
                  ),
                  padding: EdgeInsets.all(Dimensions.size20),
                  textStyle: TextStyle(
                    fontSize: Dimensions.text12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              iconButtonTheme: IconButtonThemeData(
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.square(
                    Dimensions.size45 + Dimensions.size3,
                  ),
                ),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              fontFamily: "Manrope",
              colorScheme: AppColors.darkColorScheme,
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.size10),
                    smoothness: 1,
                  ),
                  padding: EdgeInsets.all(Dimensions.size20),
                  textStyle: TextStyle(
                    fontSize: Dimensions.text12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.size10),
                    smoothness: 1,
                  ),
                  padding: EdgeInsets.all(Dimensions.size20),
                  textStyle: TextStyle(
                    fontSize: Dimensions.text12,
                    fontWeight: FontWeight.w500,
                  ),
                  foregroundColor: AppColors.onSurface(),
                  iconColor: AppColors.onSurface(),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.size10),
                    smoothness: 1,
                  ),
                  padding: EdgeInsets.all(Dimensions.size20),
                  textStyle: TextStyle(
                    fontSize: Dimensions.text12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              iconButtonTheme: IconButtonThemeData(
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.square(
                    Dimensions.size45 + Dimensions.size3,
                  ),
                ),
              ),
            ),
            builder: (BuildContext context, Widget? child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.0),
                ),
                child: child ?? Container(),
              );
            },
          ),
        ),
      ),
    );
  }
}

class DismissKeyboard extends StatelessWidget {
  final Widget child;

  const DismissKeyboard({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);

        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: child,
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({
    super.key,
  });

  @override
  SignInPageState createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> with WidgetsBindingObserver {
  final TextEditingController tecUsername = TextEditingController();
  final TextEditingController tecPassword = TextEditingController();
  final GlobalKey<FormState> formState = GlobalKey<FormState>(debugLabel: "formState");

  bool obscurePassword = true;

  String deviceId = "0000000000000000";

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    getDeviceId();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      context: context,
      appBar: BaseAppBar(
        context: context,
        name: "Login",
        description: "Device id : $deviceId",
      ),
      contentBuilder: () {
        return SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(Dimensions.size20),
          child: Column(
            children: [
              Form(
                key: formState,
                child: AutofillGroup(
                  child: Column(
                    children: [
                      BaseWidgets.text(
                        label: "Username",
                        mandatory: true,
                        readonly: false,
                        controller: tecUsername,
                        prefixIcon: const Icon(Icons.account_circle),
                      ),
                      SizedBox(height: Dimensions.size15),
                      BaseWidgets.text(
                        label: "Password",
                        mandatory: true,
                        readonly: false,
                        controller: tecPassword,
                        obscureText: obscurePassword,
                        prefixIcon: const Icon(Icons.password),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: Dimensions.size15),
              SizedBox(
                width: Dimensions.screenWidth,
                child: FilledButton(
                  onPressed: () async {
                    if (formState.currentState != null && formState.currentState!.validate()) {
                      try {
                        context.loaderOverlay.show();

                        Dio dio = Dio(
                          BaseOptions(
                            baseUrl: baseUrl,
                            connectTimeout: const Duration(seconds: 60),
                            receiveTimeout: const Duration(seconds: 60),
                            contentType: Headers.jsonContentType,
                          ),
                        );

                        dio.interceptors.add(
                          LogInterceptor(
                            requestBody: true,
                            responseBody: true,
                            error: true,
                            request: true,
                            requestHeader: true,
                            responseHeader: true,
                          ),
                        );

                        (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
                          HttpClient httpClient = HttpClient()..badCertificateCallback = (cert, host, port) => true;

                          return httpClient;
                        };

                        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

                        Response response = await dio.post(
                          "v1/sign-in",
                          data: {
                            "T": timestamp,
                            "P": sha256("$salt${tecUsername.text}$timestamp"),
                            "UN": tecUsername.text,
                            "PW": sha256(tecUsername.text + tecPassword.text),
                            "MD": deviceId,
                            "AV": "",
                            "TD": "",
                            "OS": "",
                            "FT": "",
                          },
                        );

                        if (response.statusCode == 200) {
                          Map<String, dynamic> json = response.data;

                          int responseCode = Formats.tryParseNumber(json["RC"]).toInt();

                          if (responseCode == 0) {
                            await BasePreferences.getInstance().setString(sessionIdKey, json["SI"]);
                            await BasePreferences.getInstance().setString(usernameKey, json["UN"]);

                            context.go("/");
                          } else {
                            BaseOverlays.error(message: json["RM"]);
                          }
                        }
                      } catch (e, stack) {
                        if (kDebugMode) {
                          print(stack);
                        }

                        BaseOverlays.error(message: "Something wrong, please try again");
                      } finally {
                        context.loaderOverlay.hide();
                      }
                    }
                  },
                  child: Text("Login"),
                ),
              ),
            ],
          ),
        ),
        );
      },
      statusBuilder: () => BaseBodyStatus.loaded,
    );
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();

    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();

    WidgetsBinding.instance.removeObserver(this);
  }

  String sha256(String? data) {
    if (data != null) {
      List<int> encode = utf8.encode(data);

      return crypto.sha256.convert(encode).toString();
    }

    return "";
  }

  void getDeviceId() async {
    if (kReleaseMode) {
      DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

      if (Platform.isIOS) {
        deviceId = "0000000000000000";
      } else {
        AndroidDeviceInfo androidDeviceInfo = await deviceInfoPlugin.androidInfo;

        deviceId = androidDeviceInfo.androidId.toString();
      }
    } else {
      if (Platform.isIOS) {
        deviceId = "0000000000000000";
      } else {
        deviceId = "d4db82b1a0b16901";
      }
    }

    setState(() {});
  }
}






class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return BaseScaffold(
      context: context,
      appBar: BaseAppBar(
        context: context,
        name: "Home",
        description: BasePreferences.getInstance().getString(usernameKey),
      ),
      contentBuilder: body,
      statusBuilder: () => BaseBodyStatus.loaded,
    );
  }

  @override
  void dispose() {
    super.dispose();

    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();

    setState(() {});
  }

  Widget body() {
    Widget item({
      required Color backgroundColor,
      required Color fontColor,
      required IconData iconData,
      required String title,
      required void Function() onTap,
      bool disabled = false,
    }) {
      return InkWell(
        onTap: disabled ? null : onTap,
        customBorder: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size15),
          smoothness: 1,
        ),
        child: Ink(
          width: double.infinity,
          height: Dimensions.size100,
          decoration: ShapeDecoration(
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size15),
              smoothness: 1,
              side: BorderSide(
                color: AppColors.outline(),
              ),
            ),
            color: backgroundColor,
          ),
          padding: EdgeInsets.symmetric(
            vertical: Dimensions.size10,
            horizontal: Dimensions.size5,
          ),
          child: Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  iconData,
                  size: Dimensions.size35,
                  color: fontColor,
                ),
                SizedBox(height: Dimensions.size5),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: fontColor,
                    fontSize: Dimensions.text11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        Dimensions.size15,
        Dimensions.size15,
        Dimensions.size15,
        0,
      ),
      child: Wrap(
        direction: Axis.horizontal,
        spacing: Dimensions.size10,
        runSpacing: Dimensions.size10,
        children: [
          item(
            backgroundColor: AppColors.surfaceContainerLowest(),
            fontColor: AppColors.onSurface(),
            iconData: Icons.dynamic_form,
            title: "Dynamic Form & Report",
            onTap: () async {
              await context.push("/dynamic-forms/menus");
            },
          ),
          item(
            backgroundColor: AppColors.surfaceContainerLowest(),
            fontColor: AppColors.onSurface(),
            iconData: Icons.dashboard_outlined,
            title: "Dynamic Chart",
            onTap: () async {
              await context.push("/dynamic-charts");
            },
          ),
          item(
            backgroundColor: AppColors.errorContainer(),
            fontColor: AppColors.onErrorContainer(),
            iconData: Icons.logout,
            title: "Sign Out",
            onTap: () async {
              await BaseDialogs.confirmation(
                title: "Are you sure want to proceed?",
                positiveCallback: () async {
                  await BasePreferences.getInstance().clear();

                  context.go("/");
                },
              );
            },
          ),
        ],
      ),
    );
  }
}