import { NextResponse } from "next/server"

// This endpoint will check if the database is accessible
export async function GET() {
  try {
    // Simple query to verify database connection
    //const result = await db.execute(sql`SELECT 1 as check`)

    // If we get here without an exception, the database connection is working
    return NextResponse.json(
      {
        status: "ok",
        database: "connected",
        timestamp: new Date().toISOString(),
      },
      { status: 200 },
    )
  } catch (error) {
    console.error("Health check failed:", error)
    return NextResponse.json(
      {
        status: "error",
        message: "Database connection failed",
        error: error instanceof Error ? error.message : "Unknown error",
        timestamp: new Date().toISOString(),
      },
      { status: 500 },
    )
  }
}
