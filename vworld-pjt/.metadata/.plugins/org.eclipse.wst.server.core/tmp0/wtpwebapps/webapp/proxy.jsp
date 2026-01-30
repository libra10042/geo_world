<%@page import="java.util.stream.Collectors"%>
<%@page import="java.nio.charset.StandardCharsets"%>
<%@page session="true"%>
<%@page import="java.util.Set"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.HashMap"%>
<%@page import="java.util.Iterator"%>
<%@page import="java.net.*"%>
<%@page import="java.io.*"%>
<%@page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>


<%

	OutputStream ostream = null;
	InputStream in = null;

	try {

		String orginalUrl = "url";

		int connectTimeout = 20000;		// [millisecond]
		int readTimeout = 20000;			// [millisecond]
		int maxInactiveInterval = 3600;		// [second]

		// session 갱신
		request.getSession().setMaxInactiveInterval(maxInactiveInterval);
		// 한글인코딩 tomcat server.xml UTF-8로 수정필요
		request.setCharacterEncoding("UTF-8");	

		// GET방식에서 key, value를 url에 넣는 과정
		Map paramMap = request.getParameterMap();
		// post, get에서 쓸 url을 각각 지정
		String reqUrl = ((String[])paramMap.get(orginalUrl))[0];
		// kvp 파라미터 정리
		String middleUrl = "";

		if(reqUrl.indexOf("?") == -1){
			reqUrl = reqUrl + "?";
		} else {
			if (reqUrl.charAt(reqUrl.length()-1) != '?') {
				String[] tempUrl = reqUrl.split("\\?");
				String[] midUrl = tempUrl[1].split("\\=");
				if (midUrl.length == 2) {
					middleUrl = midUrl[0] + "=" + URLEncoder.encode(midUrl[1], "UTF-8") + "&";
				}
				reqUrl = tempUrl[0] + "?";
			}
		}
		Iterator iterator = paramMap.keySet().iterator();
		while (iterator.hasNext()) {

			String key = (String) iterator.next();

			if (key.equalsIgnoreCase(orginalUrl)) {
				continue;
			}

			String values[] = (String[]) paramMap.get(key);

			if (values[0] != null) {
				middleUrl = middleUrl + key + "=" + URLEncoder.encode(values[0], "UTF-8") + "&";
			}
		}

		String resultUrl = reqUrl + middleUrl;
		
		/* url parameter XSS 필터*/
		ServletContext servletContext = getServletContext();
		URL url = null;
		HttpURLConnection con = null;

		if (request.getMethod().equalsIgnoreCase("GET")) {		// GET Method
			url = new URL(resultUrl);
			con = (HttpURLConnection) url.openConnection();
			con.setDoOutput(true);
			con.setRequestMethod(request.getMethod());
			con.setRequestProperty("charset", "UTF-8");
			con.setRequestProperty("E3MAP_PID", request.getSession().getId());		// session through proxy
		} else {		// POST Method
			url = new URL(reqUrl);
			String cType = request.getContentType();
			
			// POST방식에서 inputStream을 StringBuilder에 붙임
			StringBuilder sb = new StringBuilder();
			InputStreamReader is = new InputStreamReader(request.getInputStream());
			BufferedReader br = new BufferedReader(is);
			String read = br.readLine();

			while (read != null) {
				sb.append(read);
				read = br.readLine();
			}

			String strBody = sb.toString();
			// //System.out.println("before body : " + strBody);

			con = (HttpURLConnection) url.openConnection();
			con.setRequestMethod(request.getMethod());
			con.setDoOutput(true);
			con.setUseCaches(false);
			con.setRequestProperty("charset", "UTF-8");
			con.setRequestProperty("E3MAP_PID", request.getSession().getId());		// session through proxy

			if (strBody.trim().startsWith("<")) {
				// XML of Post Method
				con.setRequestProperty("Content-Type", "application/xml");
			} else {
				// KVP of Post Method
				strBody = strBody + middleUrl;
				con.setRequestProperty("Content-Type", request.getContentType());
			}
			// StringBuilder를 byte화 시켜서 post로 넘어온 데이터를 담는다
			byte[] postData = strBody.getBytes();
			con.setRequestProperty("Content-Length", Integer.toString(postData.length));
			con.getOutputStream().write(postData);

		}

		out.clear();
		out = pageContext.pushBody();
		ostream = response.getOutputStream();
		response.setContentType(con.getContentType());

		in = con.getInputStream();
		final int length = 5000;
		byte[] bytes = new byte[length]; 
		int bytesRead = 0;
		
		if (resultUrl.contains("callback=") && con.getContentType().contains("/json")) {

			String callBack = request.getParameter("callback");
			String strBody = new BufferedReader(
				      new InputStreamReader(in, StandardCharsets.UTF_8))
				        .lines()
				        .collect(Collectors.joining("\n"));

			String callBackCall = callBack + "('" + strBody + "')";
			ostream.write(callBackCall.getBytes());
			
		} else {
			while ((bytesRead = in.read(bytes, 0, length)) > 0) {
				ostream.write(bytes, 0, bytesRead);
			}	
		}
	} catch (Exception e) {
		System.out.println("*** proxy exception : " + e);
		response.setStatus(500);
	} finally {
		if (ostream != null) {
			ostream.flush();
			ostream.close();
			ostream = null;
		}

		if (in != null) {
			in.close();
			in = null;
		}

	}
%>